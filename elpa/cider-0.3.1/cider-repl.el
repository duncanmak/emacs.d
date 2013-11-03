;;; cider-repl-mode.el --- REPL interactions

;; Copyright © 2012-2013 Tim King, Phil Hagelberg
;; Copyright © 2013 Bozhidar Batsov, Hugo Duncan, Steve Purcell
;;
;; Author: Tim King <kingtim@gmail.com>
;;         Phil Hagelberg <technomancy@gmail.com>
;;         Bozhidar Batsov <bozhidar@batsov.com>
;;         Hugo Duncan <hugo@hugoduncan.org>
;;         Steve Purcell <steve@sanityinc.com>

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;; This file is not part of GNU Emacs.

;;; Commentary:

;; REPL interactions.

;;; Code:

(require 'nrepl-client)
(require 'cider-interaction)
(require 'cider-version)

(defgroup cider-repl nil
  "Interaction with the REPL."
  :prefix "cider-repl-"
  :group 'cider)

(defface cider-repl-prompt-face
  '((t (:inherit font-lock-keyword-face)))
  "Face for the prompt in the REPL buffer."
  :group 'cider-repl)

(defface cider-repl-output-face
  '((t (:inherit font-lock-string-face)))
  "Face for output in the REPL buffer."
  :group 'cider-repl)

(defface cider-repl-input-face
  '((t (:bold t)))
  "Face for previous input in the REPL buffer."
  :group 'cider-repl)

(defface cider-repl-result-face
  '((t ()))
  "Face for the result of an evaluation in the REPL buffer."
  :group 'cider-repl)

(defcustom cider-repl-popup-stacktraces nil
  "Non-nil means pop-up error stacktraces in the REPL buffer.
Nil means show only an error message in the minibuffer.  This variable
overrides `cider-popup-stacktraces' in REPL buffers."
  :type 'boolean
  :group 'cider-repl)

(defcustom cider-repl-pop-to-buffer-on-connect t
  "Controls whether to pop to the REPL buffer on connect.

When set to nil the buffer will only be created."
  :type 'boolean
  :group 'cider-repl)

(defcustom cider-repl-display-in-current-window nil
  "Controls whether the REPL buffer is displayed in the current window."
  :type 'boolean
  :group 'cider-repl)

(defcustom cider-repl-use-pretty-printing nil
  "Control whether the results in REPL are pretty-printed or not.
The `cider-toggle-pretty-printing' command can be used to interactively
change the setting's value."
  :type 'boolean
  :group 'cider-repl)

(defcustom cider-repl-tab-command 'cider-indent-and-complete-symbol
  "Select the command to be invoked by the TAB key.
The default option is `cider-indent-and-complete-symbol'.  If
you'd like to use the default Emacs behavior use
`indent-for-tab-command'."
  :type 'symbol
  :group 'cider-repl)

(defcustom cider-lein-command
  "lein"
  "The command used to execute leiningen 2.x."
  :type 'string
  :group 'cider-repl)

(defcustom cider-server-command
  (if (or (locate-file cider-lein-command exec-path)
          (locate-file (format "%s.bat" cider-lein-command) exec-path))
      (format "%s repl :headless" cider-lein-command)
    (format "echo \"%s repl :headless\" | eval $SHELL -l" cider-lein-command))
  "The command used to start the nREPL via command `cider-jack-in'.
For a remote nREPL server lein must be in your PATH.  The remote
proc is launched via sh rather than bash, so it might be necessary
to specific the full path to it.  Localhost is assumed."
  :type 'string
  :group 'cider-repl)

;;;; REPL buffer local variables
(defvar cider-repl-input-start-mark)

(defvar cider-repl-prompt-start-mark)

(defvar cider-repl-old-input-counter 0
  "Counter used to generate unique `cider-old-input' properties.
This property value must be unique to avoid having adjacent inputs be
joined together.")

(defvar cider-repl-input-history '()
  "History list of strings read from the nREPL buffer.")

(defvar cider-repl-input-history-items-added 0
  "Variable counting the items added in the current session.")

(defvar cider-repl-output-start nil
  "Marker for the start of output.")

(defvar cider-repl-output-end nil
  "Marker for the end of output.")

(nrepl-make-variables-buffer-local
 'cider-repl-input-start-mark
 'cider-repl-prompt-start-mark
 'cider-repl-old-input-counter
 'cider-repl-input-history
 'cider-repl-input-history-items-added
 'cider-repl-output-start
 'cider-repl-output-end)

(defun cider-repl-tab ()
  "Invoked on TAB keystrokes in `cider-repl-mode' buffers."
  (interactive)
  (funcall cider-repl-tab-command))

(defun cider-repl-reset-markers ()
  "Reset all REPL markers."
  (dolist (markname '(cider-repl-output-start
                      cider-repl-output-end
                      cider-repl-prompt-start-mark
                      cider-repl-input-start-mark))
    (set markname (make-marker))
    (set-marker (symbol-value markname) (point))))

(defmacro cider-propertize-region (props &rest body)
  "Add PROPS to all text inserted by executing BODY.
More precisely, PROPS are added to the region between the point's
positions before and after executing BODY."
  (let ((start (make-symbol "start-pos")))
    `(let ((,start (point)))
       (prog1 (progn ,@body)
         (add-text-properties ,start (point) ,props)))))

(put 'cider-propertize-region 'lisp-indent-function 1)

;;; REPL init
(defun cider-repl-buffer-name ()
  "Generate a REPL buffer name based on current connection buffer."
  (with-current-buffer (get-buffer (nrepl-current-connection-buffer))
    (nrepl-buffer-name nrepl-repl-buffer-name-template)))

(defun cider-create-repl-buffer (process)
  "Create a REPL buffer for PROCESS."
  (cider-init-repl-buffer
   process
   (let ((buffer-name (cider-repl-buffer-name)))
     (if cider-repl-display-in-current-window
         (add-to-list 'same-window-buffer-names buffer-name))
     (if cider-repl-pop-to-buffer-on-connect
         (pop-to-buffer buffer-name)
       (generate-new-buffer buffer-name))
     buffer-name)))

(defun cider-make-repl (process)
  "Make a REPL for the connection PROCESS."
  (let ((connection-buffer (process-buffer process))
        (repl-buffer (cider-create-repl-buffer process)))
    (with-current-buffer repl-buffer
      (setq nrepl-connection-buffer (buffer-name connection-buffer)))
    (with-current-buffer connection-buffer
      (setq nrepl-repl-buffer (buffer-name repl-buffer)))))

;;; Words of inspiration
(defun cider-user-first-name ()
  "Find the current user's first name."
  (let ((name (if (string= (user-full-name) "")
                  (user-login-name)
                (user-full-name))))
    (string-match "^[^ ]*" name)
    (capitalize (match-string 0 name))))

(defvar cider-words-of-inspiration
  `("The best way to predict the future is to invent it. -Alan Kay"
    "A point of view is worth 80 IQ points. -Alan Kay"
    "Lisp isn't a language, it's a building material. -Alan Kay"
    "Simple things should be simple, complex things should be possible. -Alan Kay"
    "Measuring programming progress by lines of code is like measuring aircraft building progress by weight. -Bill Gates"
    "Controlling complexity is the essence of computer programming. -Brian Kernighan"
    "The unavoidable price of reliability is simplicity. -C.A.R. Hoare"
    "You're bound to be unhappy if you optimize everything. -Donald Knuth"
    "Simplicity is prerequisite for reliability. -Edsger W. Dijkstra"
    "Deleted code is debugged code. -Jeff Sickel"
    "The key to performance is elegance, not battalions of special cases. -Jon Bentley and Doug McIlroy"
    "First, solve the problem. Then, write the code. -John Johnson"
    "Simplicity is the ultimate sophistication. -Leonardo da Vinci"
    "Programming is not about typing... it's about thinking. -Rich Hickey"
    "Design is about pulling things apart. -Rich Hickey"
    "Programmers know the benefits of everything and the tradeoffs of nothing. -Rich Hickey"
    "Code never lies, comments sometimes do. -Ron Jeffries"
    "Take this nREPL, brother, and may it serve you well."
    "Let the hacking commence!"
    "Hacks and glory await!"
    "Hack and be merry!"
    "Your hacking starts... NOW!"
    "May the Source be with you!"
    "May the Source shine upon thy nREPL!"
    "Code long and prosper!"
    "Happy hacking!"
    ,(format "%s, this could be the start of a beautiful program."
             (cider-user-first-name)))
  "Scientifically-proven optimal words of hackerish encouragement.")

(defun cider-random-words-of-inspiration ()
  "Select a random entry from `cider-words-of-inspiration'."
  (eval (nth (random (length cider-words-of-inspiration))
             cider-words-of-inspiration)))

(defun cider--banner ()
  "Generate the welcome REPL buffer banner."
  (format "; CIDER %s (Clojure %s, nREPL %s)"
          (cider-version)
          (cider--clojure-version)
          (cider--backend-version)))

(defun cider-insert-banner-and-prompt (ns)
  "Insert REPL banner and REPL prompt, taking into account NS."
  (when (zerop (buffer-size))
    (insert (propertize (cider--banner) 'face 'font-lock-comment-face)))
  (goto-char (point-max))
  (cider-mark-output-start)
  (cider-mark-input-start)
  (cider-insert-prompt ns))


(defun cider-init-repl-buffer (connection buffer &optional noprompt)
  "Initialize the REPL for CONNECTION in BUFFER.
Insert a banner, unless NOPROMPT is non-nil."
  (with-current-buffer buffer
    (unless (eq major-mode 'cider-repl-mode)
      (cider-repl-mode))
    ;; use the same requires by default as clojure.main does
    (nrepl-send-string-sync nrepl-repl-requires-sexp)
    (cider-repl-reset-markers)
    (unless noprompt
      (cider-insert-banner-and-prompt nrepl-buffer-ns))
    (cider-remember-clojure-buffer cider-current-clojure-buffer)
    (current-buffer)))

(defun cider-find-or-create-repl-buffer ()
  "Return the REPL buffer, create it if necessary."
  (let ((buffer (nrepl-current-repl-buffer)))
        (if (null buffer)
                (error "No active nREPL connection")
          (let ((buffer (get-buffer buffer)))
                (or (when (buffer-live-p buffer) buffer)
                        (let ((buffer (nrepl-current-connection-buffer)))
                          (if (null buffer)
                                  (error "No active nREPL connection")
                                (cider-init-repl-buffer
                                 (get-process buffer)
                                 (get-buffer-create
                                  (cider-repl-buffer-name))))))))))


;;; REPL interaction
(defun cider-property-bounds (prop)
  "Return the the positions of the previous and next change to PROP.
PROP is the name of a text property."
  (assert (get-text-property (point) prop))
  (let ((end (next-single-char-property-change (point) prop)))
    (list (previous-single-char-property-change end prop) end)))

(defun cider-in-input-area-p ()
  "Return t if in input area."
  (<= cider-repl-input-start-mark (point)))

(defun cider-current-input (&optional until-point-p)
  "Return the current input as string.
The input is the region from after the last prompt to the end of
buffer.  If UNTIL-POINT-P is non-nil, the input is until the current
point."
  (buffer-substring-no-properties cider-repl-input-start-mark
                                  (if until-point-p
                                      (point)
                                    (point-max))))

(defun cider-previous-prompt ()
  "Move backward to the previous prompt."
  (interactive)
  (cider-find-prompt t))

(defun cider-next-prompt ()
  "Move forward to the next prompt."
  (interactive)
  (cider-find-prompt))

(defun cider-find-prompt (&optional backward)
  "Find the next prompt.
If BACKWARD is non-nil look backward."
  (let ((origin (point))
        (prop 'cider-prompt))
    (while (progn
             (cider-search-property-change prop backward)
             (not (or (cider-end-of-proprange-p prop) (bobp) (eobp)))))
    (unless (cider-end-of-proprange-p prop)
      (goto-char origin))))

(defun cider-search-property-change (prop &optional backward)
  "Search forward for a property change to PROP.
If BACKWARD is non-nil search backward."
  (cond (backward
         (goto-char (previous-single-char-property-change (point) prop)))
        (t
         (goto-char (next-single-char-property-change (point) prop)))))

(defun cider-end-of-proprange-p (property)
  "Return t if at the the end of a property range for PROPERTY."
  (and (get-char-property (max 1 (1- (point))) property)
       (not (get-char-property (point) property))))

(defun cider-mark-input-start ()
  "Mark the input start."
  (set-marker cider-repl-input-start-mark (point) (current-buffer)))

(defun cider-mark-output-start ()
  "Mark the output start."
  (set-marker cider-repl-output-start (point))
  (set-marker cider-repl-output-end (point)))

(defun cider-mark-output-end ()
  "Marke the output end."
  (add-text-properties cider-repl-output-start cider-repl-output-end
                       '(face cider-repl-output-face
                              rear-nonsticky (face))))

;;;;; History

(defcustom cider-wrap-history nil
  "T to wrap history around when the end is reached."
  :type 'boolean
  :group 'cider-repl)

;; These two vars contain the state of the last history search.  We
;; only use them if `last-command' was 'cider-history-replace,
;; otherwise we reinitialize them.

(defvar cider-repl-input-history-position -1
  "Newer items have smaller indices.")

(defvar cider-history-pattern nil
  "The regexp most recently used for finding input history.")

(defun cider-add-to-input-history (string)
  "Add STRING to the input history.
Empty strings and duplicates are ignored."
  (unless (or (equal string "")
              (equal string (car cider-repl-input-history)))
    (push string cider-repl-input-history)
    (incf cider-repl-input-history-items-added)))

(defun cider-delete-current-input ()
  "Delete all text after the prompt."
  (interactive)
  (goto-char (point-max))
  (delete-region cider-repl-input-start-mark (point-max)))

(defun cider-replace-input (string)
  "Replace the current REPL input with STRING."
  (cider-delete-current-input)
  (insert-and-inherit string))

(defun cider-position-in-history (start-pos direction regexp)
  "Return the position of the history item starting at START-POS.
Search in DIRECTION for REGEXP.
Return -1 resp the length of the history if no item matches."
  ;; Loop through the history list looking for a matching line
  (let* ((step (ecase direction
                 (forward -1)
                 (backward 1)))
         (history cider-repl-input-history)
         (len (length history)))
    (loop for pos = (+ start-pos step) then (+ pos step)
          if (< pos 0) return -1
          if (<= len pos) return len
          if (string-match regexp (nth pos history)) return pos)))

(defun cider-history-replace (direction &optional regexp)
  "Replace the current input with the next line in DIRECTION.
DIRECTION is 'forward' or 'backward' (in the history list).
If REGEXP is non-nil, only lines matching REGEXP are considered."
  (setq cider-history-pattern regexp)
  (let* ((min-pos -1)
         (max-pos (length cider-repl-input-history))
         (pos0 (cond ((cider-history-search-in-progress-p)
                      cider-repl-input-history-position)
                     (t min-pos)))
         (pos (cider-position-in-history pos0 direction (or regexp "")))
         (msg nil))
    (cond ((and (< min-pos pos) (< pos max-pos))
           (cider-replace-input (nth pos cider-repl-input-history))
           (setq msg (format "History item: %d" pos)))
          ((not cider-wrap-history)
           (setq msg (cond ((= pos min-pos) "End of history")
                           ((= pos max-pos) "Beginning of history"))))
          (cider-wrap-history
           (setq pos (if (= pos min-pos) max-pos min-pos))
           (setq msg "Wrapped history")))
    (when (or (<= pos min-pos) (<= max-pos pos))
      (when regexp
        (setq msg (concat msg "; no matching item"))))
    (message "%s%s" msg (cond ((not regexp) "")
                              (t (format "; current regexp: %s" regexp))))
    (setq cider-repl-input-history-position pos)
    (setq this-command 'cider-history-replace)))

(defun cider-history-search-in-progress-p ()
  "Return t if a current history search is in progress."
  (eq last-command 'cider-history-replace))

(defun cider-terminate-history-search ()
  "Terminate the current history search."
  (setq last-command this-command))

(defun cider-previous-input ()
  "Cycle backwards through input history.
If the `last-command' was a history navigation command use the
same search pattern for this command.
Otherwise use the current input as search pattern."
  (interactive)
  (cider-history-replace 'backward (cider-history-pattern t)))

(defun cider-next-input ()
  "Cycle forwards through input history.
See `cider-previous-input'."
  (interactive)
  (cider-history-replace 'forward (cider-history-pattern t)))

(defun cider-forward-input ()
  "Cycle forwards through input history."
  (interactive)
  (cider-history-replace 'forward (cider-history-pattern)))

(defun cider-backward-input ()
  "Cycle backwards through input history."
  (interactive)
  (cider-history-replace 'backward (cider-history-pattern)))

(defun cider-previous-matching-input (regexp)
  "Find the previous input matching REGEXP."
  (interactive "sPrevious element matching (regexp): ")
  (cider-terminate-history-search)
  (cider-history-replace 'backward regexp))

(defun cider-next-matching-input (regexp)
  "Find then next input matching REGEXP."
  (interactive "sNext element matching (regexp): ")
  (cider-terminate-history-search)
  (cider-history-replace 'forward regexp))

(defun cider-history-pattern (&optional use-current-input)
  "Return the regexp for the navigation commands.
If USE-CURRENT-INPUT is non-nil, use the current input."
  (cond ((cider-history-search-in-progress-p)
         cider-history-pattern)
        (use-current-input
         (assert (<= cider-repl-input-start-mark (point)))
         (let ((str (cider-current-input t)))
           (cond ((string-match "^[ \n]*$" str) nil)
                 (t (concat "^" (regexp-quote str))))))
        (t nil)))

;;; persistent history
(defcustom cider-history-size 500
  "The maximum number of items to keep in the REPL history."
  :type 'integer
  :safe 'integerp
  :group 'cider-repl-mode)

(defcustom cider-history-file nil
  "File to save the persistent REPL history to."
  :type 'string
  :safe 'stringp
  :group 'cider-repl-mode)

(defun cider-history-read-filename ()
  "Ask the user which file to use, defaulting `cider-history-file'."
  (read-file-name "Use nREPL history file: "
                  cider-history-file))

(defun cider-history-read (filename)
  "Read history from FILENAME and return it.
It does not yet set the input history."
  (if (file-readable-p filename)
      (with-temp-buffer
        (insert-file-contents filename)
        (read (current-buffer)))
    '()))

(defun cider-history-load (&optional filename)
  "Load history from FILENAME into current session.
FILENAME defaults to the value of `cider-history-file' but user
defined filenames can be used to read special history files.

The value of `cider-repl-input-history' is set by this function."
  (interactive (list (cider-history-read-filename)))
  (let ((f (or filename cider-history-file)))
    ;; TODO: probably need to set cider-repl-input-history-position as well.
    ;; in a fresh connection the newest item in the list is currently
    ;; not available.  After sending one input, everything seems to work.
    (setq cider-repl-input-history (cider-history-read f))))

(defun cider-history-write (filename)
  "Write history to FILENAME.
Currently coding system for writing the contents is hardwired to
utf-8-unix."
  (let* ((mhist (cider-histories-merge cider-repl-input-history
                                       cider-repl-input-history-items-added
                                       (cider-history-read filename)))
         ;; newest items are at the beginning of the list, thus 0
         (hist (cl-subseq mhist 0 (min (length mhist) cider-history-size))))
    (unless (file-writable-p filename)
      (error (format "History file not writable: %s" filename)))
    (let ((print-length nil) (print-level nil))
      (with-temp-file filename
        ;; TODO: really set cs for output
        ;; TODO: does cs need to be customizable?
        (insert ";; -*- coding: utf-8-unix -*-\n")
        (insert ";; Automatically written history of nREPL session\n")
        (insert ";; Edit at your own risk\n\n")
        (prin1 (mapcar #'substring-no-properties hist) (current-buffer))))))

(defun cider-history-save (&optional filename)
  "Save the current nREPL input history to FILENAME.
FILENAME defaults to the value of `cider-history-file'."
  (interactive (list (cider-history-read-filename)))
  (let* ((file (or filename cider-history-file)))
    (cider-history-write file)))

(defun cider-history-just-save ()
  "Just save the history to `cider-history-file'.
This function is meant to be used in hooks to avoid lambda
constructs."
  (cider-history-save cider-history-file))

;; SLIME has different semantics and will not save any duplicates.
;; we keep track of how many items were added to the history in the
;; current session in cider-add-to-input-history and merge only the
;; new items with the current history found in the file, which may
;; have been changed in the meantime by another session
(defun cider-histories-merge (session-hist n-added-items file-hist)
  "Merge histories from SESSION-HIST adding N-ADDED-ITEMS into FILE-HIST."
  (append (cl-subseq session-hist 0 n-added-items)
          file-hist))

;;;
(defun cider-same-line-p (pos1 pos2)
  "Return t if buffer positions POS1 and POS2 are on the same line."
  (save-excursion (goto-char (min pos1 pos2))
                  (<= (max pos1 pos2) (line-end-position))))

(defun cider-bol-internal ()
  "Go to the beginning of line or the prompt."
  (cond ((and (>= (point) cider-repl-input-start-mark)
              (cider-same-line-p (point) cider-repl-input-start-mark))
         (goto-char cider-repl-input-start-mark))
        (t (beginning-of-line 1))))

(defun cider-bol ()
  "Go to the beginning of line or the prompt."
  (interactive)
  (deactivate-mark)
  (cider-bol-internal))

(defun cider-bol-mark ()
  "Set the mark and go to the beginning of line or the prompt."
  (interactive)
  (unless mark-active
    (set-mark (point)))
  (cider-bol-internal))

(defun cider-at-prompt-start-p ()
  "Return t if point is at the start of prompt.
This will not work on non-current prompts."
  (= (point) cider-repl-input-start-mark))

(defun cider-show-maximum-output ()
  "Put the end of the buffer at the bottom of the window."
  (when (eobp)
    (let ((win (get-buffer-window (current-buffer))))
      (when win
        (with-selected-window win
          (set-window-point win (point-max))
          (recenter -1))))))

(defmacro cider-save-marker (marker &rest body)
  "Save MARKER and execute BODY."
  (let ((pos (make-symbol "pos")))
    `(let ((,pos (marker-position ,marker)))
       (prog1 (progn . ,body)
         (set-marker ,marker ,pos)))))

(put 'cider-save-marker 'lisp-indent-function 1)

(defun cider-insert-prompt (namespace)
  "Insert the prompt (before markers!), taking into account NAMESPACE.
Set point after the prompt.
Return the position of the prompt beginning."
  (goto-char cider-repl-input-start-mark)
  (cider-save-marker cider-repl-output-start
    (cider-save-marker cider-repl-output-end
      (unless (bolp) (insert-before-markers "\n"))
      (let ((prompt-start (point))
            (prompt (format "%s> " namespace)))
        (cider-propertize-region
            '(face cider-repl-prompt-face read-only t intangible t
                   cider-prompt t
                   rear-nonsticky (cider-prompt read-only face intangible))
          (insert-before-markers prompt))
        (set-marker cider-repl-prompt-start-mark prompt-start)
        prompt-start))))

(defun cider-emit-output-at-pos (buffer string position &optional bol)
  "Using BUFFER, insert STRING at POSITION and mark it as output.
If BOL is non-nil insert at the beginning of line."
  (with-current-buffer buffer
    (save-excursion
      (cider-save-marker cider-repl-output-start
        (cider-save-marker cider-repl-output-end
          (goto-char position)
          (when (and bol (not (bolp))) (insert-before-markers "\n"))
          (cider-propertize-region `(face cider-repl-output-face
                                          rear-nonsticky (face))
            (insert-before-markers string)
            (when (and (= (point) cider-repl-prompt-start-mark)
                       (not (bolp)))
              (insert-before-markers "\n")
              (set-marker cider-repl-output-end (1- (point))))))))
    (cider-show-maximum-output)))

(defun cider-emit-interactive-output (string)
  "Emit STRING as interactive output."
  (with-current-buffer (nrepl-current-repl-buffer)
    (let ((pos (1- (cider-input-line-beginning-position))))
      (cider-emit-output-at-pos (current-buffer) string pos t)
      (ansi-color-apply-on-region pos (point-max)))))

(defun cider-emit-output (buffer string &optional bol)
  "Using BUFFER, emit STRING.
If BOL is non-nil, emit at the beginning of the line."
  (with-current-buffer buffer
    (let ((pos (1- (cider-input-line-beginning-position))))
      (cider-emit-output-at-pos buffer string cider-repl-input-start-mark bol)
      (ansi-color-apply-on-region pos (point-max)))))

(defun cider-emit-prompt (buffer)
  "Emit the REPL prompt into BUFFER."
  (with-current-buffer buffer
    (save-excursion
      (cider-save-marker cider-repl-output-start
        (cider-save-marker cider-repl-output-end
          (cider-insert-prompt nrepl-buffer-ns))))
    (cider-show-maximum-output)))

(defun cider-emit-result (buffer string &optional bol)
  "Emit into BUFFER the result STRING and mark it as an evaluation result.
If BOL is non-nil insert at the beginning of the line."
  (with-current-buffer buffer
    (save-excursion
      (cider-save-marker cider-repl-output-start
        (cider-save-marker cider-repl-output-end
          (goto-char cider-repl-input-start-mark)
          (when (and bol (not (bolp))) (insert-before-markers "\n"))
          (cider-propertize-region `(face cider-repl-result-face
                                          rear-nonsticky (face))
            (insert-before-markers string)))))
    (cider-show-maximum-output)))


(defun cider-newline-and-indent ()
  "Insert a newline, then indent the next line.
Restrict the buffer from the prompt for indentation, to avoid being
confused by strange characters (like unmatched quotes) appearing
earlier in the buffer."
  (interactive)
  (save-restriction
    (narrow-to-region cider-repl-prompt-start-mark (point-max))
    (insert "\n")
    (lisp-indent-line)))

(defun cider-indent-and-complete-symbol ()
  "Indent the current line and perform symbol completion.
First indent the line.  If indenting doesn't move point, complete
the symbol."
  (interactive)
  (let ((pos (point)))
    (lisp-indent-line)
    (when (= pos (point))
      (if (save-excursion (re-search-backward "[^() \n\t\r]+\\=" nil t))
          (completion-at-point)))))

(defun cider-kill-input ()
  "Kill all text from the prompt to point."
  (interactive)
  (cond ((< (marker-position cider-repl-input-start-mark) (point))
         (kill-region cider-repl-input-start-mark (point)))
        ((= (point) (marker-position cider-repl-input-start-mark))
         (cider-delete-current-input))))

(defun cider-input-complete-p (start end)
  "Return t if the region from START to END is a complete sexp."
  (save-excursion
    (goto-char start)
    (cond ((looking-at "\\s *[@'`#]?[(\"]")
           (ignore-errors
             (save-restriction
               (narrow-to-region start end)
               ;; Keep stepping over blanks and sexps until the end of
               ;; buffer is reached or an error occurs. Tolerate extra
               ;; close parens.
               (loop do (skip-chars-forward " \t\r\n)")
                     until (eobp)
                     do (forward-sexp))
               t)))
          (t t))))

(defun cider-send-input (&optional newline)
  "Go to the end of the input and send the current input.
If NEWLINE is true then add a newline at the end of the input."
  (unless (cider-in-input-area-p)
    (error "No input at point"))
  (goto-char (point-max))
  (let ((end (point)))             ; end of input, without the newline
    (cider-add-to-input-history (buffer-substring cider-repl-input-start-mark end))
    (when newline
      (insert "\n")
      (cider-show-maximum-output))
    (let ((inhibit-modification-hooks t))
      (add-text-properties cider-repl-input-start-mark
                           (point)
                           `(cider-old-input
                             ,(incf cider-repl-old-input-counter))))
    (let ((overlay (make-overlay cider-repl-input-start-mark end)))
      ;; These properties are on an overlay so that they won't be taken
      ;; by kill/yank.
      (overlay-put overlay 'read-only t)
      (overlay-put overlay 'face 'cider-repl-input-face)))
  (let* ((input (cider-current-input))
         (form (if (and (not (string-match "\\`[ \t\r\n]*\\'" input)) cider-repl-use-pretty-printing)
                   (format "(clojure.pprint/pprint %s)" input) input)))
    (goto-char (point-max))
    (cider-mark-input-start)
    (cider-mark-output-start)
    (nrepl-send-string form (cider-handler (current-buffer)) nrepl-buffer-ns)))

(defun cider-return (&optional end-of-input)
  "Evaluate the current input string, or insert a newline.
Send the current input ony if a whole expression has been entered,
i.e. the parenthesis are matched.
When END-OF-INPUT is non-nil, send the input even if the parentheses
are not balanced."
  (interactive "P")
  (cond
   (end-of-input
    (cider-send-input))
   ((and (get-text-property (point) 'cider-old-input)
         (< (point) cider-repl-input-start-mark))
    (cider-grab-old-input end-of-input)
    (cider-recenter-if-needed))
   ((cider-input-complete-p cider-repl-input-start-mark (point-max))
    (cider-send-input t))
   (t
    (cider-newline-and-indent)
    (message "[input not complete]"))))

(defun cider-recenter-if-needed ()
  "Make sure that the point is visible."
  (unless (pos-visible-in-window-p (point-max))
    (save-excursion
      (goto-char (point-max))
      (recenter -1))))

(defun cider-grab-old-input (replace)
  "Resend the old REPL input at point.
If REPLACE is non-nil the current input is replaced with the old
input; otherwise the new input is appended.  The old input has the
text property `cider-old-input'."
  (multiple-value-bind (beg end) (cider-property-bounds 'cider-old-input)
    (let ((old-input (buffer-substring beg end)) ;;preserve
          ;;properties, they will be removed later
          (offset (- (point) beg)))
      ;; Append the old input or replace the current input
      (cond (replace (goto-char cider-repl-input-start-mark))
            (t (goto-char (point-max))
               (unless (eq (char-before) ?\ )
                 (insert " "))))
      (delete-region (point) (point-max))
      (save-excursion
        (insert old-input)
        (when (equal (char-before) ?\n)
          (delete-char -1)))
      (forward-char offset))))

(defun cider-closing-return ()
  "Evaluate the current input string after closing all open lists."
  (interactive)
  (goto-char (point-max))
  (save-restriction
    (narrow-to-region cider-repl-input-start-mark (point))
    (while (ignore-errors (save-excursion (backward-up-list 1)) t)
      (insert ")")))
  (cider-return))

(defun cider-toggle-pretty-printing ()
  "Toggle pretty-printing in the REPL."
  (interactive)
  (setq cider-repl-use-pretty-printing (not cider-repl-use-pretty-printing))
  (message "Pretty printing in nREPL %s."
           (if cider-repl-use-pretty-printing "enabled" "disabled")))

(defvar cider-clear-buffer-hook)

(defun cider-clear-buffer ()
  "Delete the output generated by the Clojure process."
  (interactive)
  (let ((inhibit-read-only t))
    (delete-region (point-min) cider-repl-prompt-start-mark)
    (delete-region cider-repl-output-start cider-repl-output-end)
    (when (< (point) cider-repl-input-start-mark)
      (goto-char cider-repl-input-start-mark))
    (recenter t))
  (run-hooks 'cider-clear-buffer-hook))

(defun cider-find-and-clear-repl-buffer ()
  "Find the current REPL buffer and clear it.
Returns to the buffer in which the command was invoked."
  (interactive)
  (let ((origin-buffer (current-buffer)))
    (switch-to-buffer (nrepl-current-repl-buffer))
    (cider-clear-buffer)
    (switch-to-buffer origin-buffer)))

(defun cider-input-line-beginning-position ()
  "Return the position of the beginning of input."
  (save-excursion
    (goto-char cider-repl-input-start-mark)
    (line-beginning-position)))

(defun cider-clear-output ()
  "Delete the output inserted since the last input."
  (interactive)
  (let ((start (save-excursion
                 (cider-previous-prompt)
                 (ignore-errors (forward-sexp))
                 (forward-line)
                 (point)))
        (end (1- (cider-input-line-beginning-position))))
    (when (< start end)
      (let ((inhibit-read-only t))
        (delete-region start end)
        (save-excursion
          (goto-char start)
          (insert
           (propertize ";;; output cleared" 'face 'font-lock-comment-face)))))))

(defun cider-repl-set-ns (ns)
  "Switch the namespace of the REPL buffer to NS.

If invoked in a REPL buffer the command will prompt you for the name of the
namespace to switch to."
  (interactive (list (if (eq 'cider-repl-mode (buffer-local-value 'major-mode (current-buffer)))
                         (read-from-minibuffer "Switch to namespace: ")
                       (cider-current-ns))))
  (if ns
      (with-current-buffer (nrepl-current-repl-buffer)
        (nrepl-send-string
         (format "(in-ns '%s)" ns) (cider-handler (current-buffer))))
    (message "Sorry, I don't know what the current namespace is.")))

(provide 'cider-repl)
;;; cider-repl.el ends here
