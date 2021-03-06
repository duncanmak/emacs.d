;;; init.el --- Duncan's emacs file
;;;
;;; Commentary:
;;;
;;; Code:
;;;
;; Turn off mouse interface early in startup to avoid momentary display

;; Added by Package.el.  This must come before configurations of
;; installed packages.  Don't delete this line.  If you don't want it,
;; just comment it out by adding a semicolon to the start of the line.
;; You may delete these explanatory comments.
(package-initialize)

(if (fboundp 'tool-bar-mode) (tool-bar-mode -1))

;; No splash screen please ... jeez
(setq inhibit-startup-message t)

;; Auto refresh buffers
(global-auto-revert-mode 1)

;; Also auto refresh dired, but be quiet about it
(require 'dired)
(require 'dired-x)
(setq global-auto-revert-non-file-buffers t)
(setq auto-revert-verbose nil)

(require 'package)
(add-to-list 'package-archives
             '("melpa" . "https://melpa.org/packages/"))
(when (< emacs-major-version 24)
  ;; For important compatibility libraries like cl-lib
  (add-to-list 'package-archives '("gnu" . "http://elpa.gnu.org/packages/")))
(package-initialize) ;; You might already have this line

(server-start)
(desktop-save-mode 1)
(setq-default indent-tabs-mode nil)
(emacs-lock-mode 'kill)

(let ((default-directory "~/.emacs.d/site-lisp/"))
  (normal-top-level-add-to-load-path '("."))
  (normal-top-level-add-subdirs-to-load-path))

;;; Mac specific
(when (eq system-type 'darwin)
  (require 'ls-lisp)
  (setq ls-lisp-use-insert-directory-program nil)
  (setq mac-command-key-is-meta t)
  (setq mac-command-modifier 'meta)
  (setq mac-option-key-is-meta t)
  (setq mac-option-modifier 'meta)
  (setenv "PATH" (concat "/usr/local/bin:" (getenv "PATH")))
  (push "/usr/local/bin" exec-path)
  (setenv "PATH" (concat "/usr/local/share/python:" (getenv "PATH")))
  (push "/usr/local/share/python" exec-path)
  (setenv "PATH" (concat "/usr/local/share/npm/bin:" (getenv "PATH")))
  (push "/usr/local/share/npm/bin" exec-path)
  (global-set-key "\M-`" 'other-frame)
  (set-face-attribute 'default nil :family "Menlo" :height 140)
  (set-fontset-font "fontset-default" 'unicode "Menlo")
  )

;;; Linux specific
(when (eq system-type 'gnu/linux)
  (setenv "PATH" (concat (getenv "PATH") ":/home/duncan/bin"))
  (setq ack-executable "ack-grep")
  (set-face-attribute 'default nil :family "Droid Sans Mono" :height 100)
  (set-fontset-font "fontset-default" 'unicode "Droid Sans Mono"))

;;; Windows specific
(when (eq system-type 'windows-nt)
  (push "C:\\Program Files\\Git\\bin" exec-path)
  (push "C:\\Program Files (x86)\\Git\\bin" exec-path)
  (set-face-attribute 'default nil :family "Consolas" :height 120)
  (set-fontset-font "fontset-default" 'unicode "Consolas"))

;;; windmove
(global-set-key (kbd "C-c <left>")  'windmove-left)
(global-set-key (kbd "C-c <right>") 'windmove-right)
(global-set-key (kbd "C-c <up>")    'windmove-up)
(global-set-key (kbd "C-c <down>")  'windmove-down)

;;; multiple-cursor
(global-set-key (kbd "C-S-c C-S-c") 'mc/edit-lines)
(global-set-key (kbd "C->") 'mc/mark-next-like-this)
(global-set-key (kbd "C-<") 'mc/mark-previous-like-this)
(global-set-key (kbd "C-c C-<") 'mc/mark-all-like-this)

;;; flycheck
;; (add-hook 'after-init-hook #'global-flycheck-mode)

;;; company-mode
(add-hook 'after-init-hook 'global-company-mode)

;;; shell
(defun comint-delchar-or-eof-or-kill-buffer (arg)
  (interactive "p")
  (if (null (get-buffer-process (current-buffer)))
      (kill-buffer)
    (comint-delchar-or-maybe-eof arg)))

(add-hook 'shell-mode-hook
          (lambda ()
            (define-key shell-mode-map
              (kbd "C-d") 'comint-delchar-or-eof-or-kill-buffer)))

;;; diffstat
(require 'diffstat)
(add-hook 'diff-mode-hook (lambda () (local-set-key "\C-c\C-l" 'diffstat)))

(global-set-key [remap goto-line] 'goto-line-with-feedback)

(defun goto-line-with-feedback ()
  "Show line numbers temporarily, while prompting for the line number input"
  (interactive)
  (unwind-protect
      (progn
        (linum-mode 1)
        (goto-line (read-number "Goto line: ")))
    (linum-mode -1)))

;;; recentf
(require 'recentf)
(recentf-mode 1)
(defun recentf-open-files-compl ()
  (interactive)
  (let* ((tocpl (mapcar (lambda (x) (cons (file-name-nondirectory x) x))
			recentf-list))
	 (fname (completing-read "File name: " tocpl nil nil)))
    (when fname
      (find-file (cdr (assoc-string fname tocpl))))))
(global-set-key "\C-x\C-r" 'recentf-open-files-compl)

;; (add-hook 'before-save-hook 'delete-trailing-whitespace)
;; (require 'ws-trim)
;; (global-ws-trim-mode t)

;;; iswitchb
;; (require 'iswitchb)
;; (add-to-list 'iswitchb-buffer-ignore "^ ")
;; (add-to-list 'iswitchb-buffer-ignore "*Messages*")
;; (add-to-list 'iswitchb-buffer-ignore "*ECB")
;; (add-to-list 'iswitchb-buffer-ignore "*Buffer")
;; (add-to-list 'iswitchb-buffer-ignore "*Completions")
;; (add-to-list 'iswitchb-buffer-ignore "*ftp ")
;; (add-to-list 'iswitchb-buffer-ignore "*bsh")
;; (add-to-list 'iswitchb-buffer-ignore "*jde-log")
;; (add-to-list 'iswitchb-buffer-ignore "^[tT][aA][gG][sS]$")
;; (add-to-list 'iswitchb-buffer-ignore "@")
;; (defun iswitchb-local-keys ()
;;   (mapc (lambda (K)
;;           (let* ((key (car K)) (fun (cdr K)))
;;             (define-key iswitchb-mode-map (edmacro-parse-keys key) fun)))
;;         '(("<right>" . iswitchb-next-match)
;;           ("<left>"  . iswitchb-prev-match)
;;           ("<up>"    . ignore             )
;;           ("<down>"  . ignore             ))))
;; (add-hook 'iswitchb-define-mode-map-hook 'iswitchb-local-keys)
(icomplete-mode 99)

;;; ibuffer
(global-set-key (kbd "C-x C-b") 'ibuffer)
(autoload 'ibuffer "ibuffer" "List buffers." t)
(add-hook 'ibuffer-hook
	  (lambda ()
	    (ibuffer-vc-set-filter-groups-by-vc-root)
	    (ibuffer-do-sort-by-alphabetic)))

;; Make control+pageup/down scroll the other buffer
(global-set-key [C-next]  'scroll-other-window)
(global-set-key [C-prior] 'scroll-other-window-down)

;; stops selection with a mouse being immediately injected to the kill ring
(setq mouse-drag-copy-region nil)
;; makes killing/yanking interact with clipboard X11 selection
(setq x-select-enable-clipboard t)

;; Make all "yes or no" prompts show "y or n" instead
(fset 'yes-or-no-p 'y-or-n-p)

;;; Always uniquify buffers
(require 'uniquify)
(setq
  uniquify-buffer-name-style 'post-forward
  uniquify-separator ":")

;;; Magit
(global-set-key (kbd "C-x g") 'magit-status)

(eval-after-load 'magit
  '(progn
     (defun magit-toggle-whitespace ()
       (interactive)
       (if (member "-w" magit-diff-options)
           (magit-dont-ignore-whitespace)
         (magit-ignore-whitespace)))
     (defun magit-ignore-whitespace ()
       (interactive)
       (add-to-list 'magit-diff-options "-w")
       (magit-refresh))
     (defun magit-dont-ignore-whitespace ()
       (interactive)
       (setq magit-diff-options (remove "-w" magit-diff-options))
       (magit-refresh))
     (define-key magit-status-mode-map (kbd "W") 'magit-toggle-whitespace)

     ;; full screen magit-status
     (defadvice magit-status (around magit-fullscreen activate)
       (window-configuration-to-register :magit-fullscreen)
       ad-do-it
       (delete-other-windows))

     (defun magit-quit-session ()
       "Restores the previous window configuration and kills the magit buffer"
       (interactive)
       (kill-buffer)
       (jump-to-register :magit-fullscreen))

     (define-key magit-status-mode-map (kbd "q") 'magit-quit-session)
     ))

(delete-selection-mode t)
(show-paren-mode t)

;;; html
(eval-after-load "sgml-mode"
  '(progn
     (require 'tagedit)
     (tagedit-add-paredit-like-keybindings)
     (add-hook 'html-mode-hook (lambda () (tagedit-mode 1)))))
(add-hook 'sgml-mode-hook 'zencoding-mode) ;; Auto-start on any markup modes
(add-hook 'css-mode-hook  'zencoding-mode) ;; enable Emmet's css abbreviation.

;;; lisp
(defun lisp-hook ()
  (require 'paredit)
  (require 'eldoc) ; if not already loaded
  (turn-on-eldoc-mode)
  (imenu-add-menubar-index)
  (eldoc-add-command
   'paredit-backward-delete
   'paredit-close-round)
  (paredit-mode +1)
  (define-key paredit-mode-map (kbd "C-j") nil)
  (define-key paredit-mode-map (kbd "[") 'paredit-open-round)
  (define-key paredit-mode-map (kbd "]") 'paredit-close-round)
  (define-key paredit-mode-map (kbd "(") 'paredit-open-square)
  (define-key paredit-mode-map (kbd ")") 'paredit-close-square)
  (define-key paredit-mode-map (kbd "{") 'paredit-open-curly)
  (define-key paredit-mode-map (kbd "}") 'paredit-close-curly))

(add-hook 'clojure-mode-hook          'lisp-hook)
(add-hook 'emacs-lisp-mode-hook       'lisp-hook)
(add-hook 'lisp-interaction-mode-hook 'lisp-hook)
(add-hook 'scheme-mode-hook           'lisp-hook)
(add-hook 'lisp-mode-hook             'lisp-hook)

(defun c-hook ()
  (imenu-add-menubar-index)
  (subword-mode +1)
  (electric-pair-mode +1)
  (electric-indent-mode +1))

;;; java
(add-hook 'java-mode-hook 'c-hook)

;; (require 'cedet)
;; (require 'semantic)
;; (load "semantic/loaddefs.el")
;; (semantic-mode 1)
;; (require 'malabar-mode)
;; (add-to-list 'auto-mode-alist '("\\.java\\'" . malabar-mode))

;;; typescript
(setenv "NODE_NO_READLINE" "1")
(setq inferior-js-program-command "node")
(setq inferior-js-mode-hook
      (lambda ()
        ;; We like nice colors
        (ansi-color-for-comint-mode-on)
        ;; Deal with some prompt nonsense
        (add-to-list
         'comint-preoutput-filter-functions
         (lambda (output)
           (replace-regexp-in-string "\033\\[[0-9]+[GK]" "" output)
           (replace-regexp-in-string ".*1G.*3G" "&GT;" output)
           (replace-regexp-in-string "&GT;" "> " output)))))

(require 'typescript)
(add-to-list 'auto-mode-alist '("\\.ts$" . typescript-mode))

;;; javascript
(autoload 'js2-mode "js2-mode" nil t)
(add-to-list 'auto-mode-alist '("\\.js$" . js2-mode))
;; (flycheck-define-checker javascript-jslint-reporter
;;   "A JavaScript syntax and style checker based on JSLint Reporter.

;; See URL `https://github.com/FND/jslint-reporter'."
;;   :command ("~/.emacs.d/site-lisp/jslint-reporter/jslint-reporter" source)
;;   :error-patterns
;;   ((error line-start (1+ nonl) ":" line ":" column ":" (message) line-end))
;;   :modes (js-mode js2-mode js3-mode))

(add-hook 'js2-mode-hook
          (lambda ()
            (subword-mode)
            (electric-indent-mode +1)
            (electric-pair-mode +1)
            (local-set-key (kbd "C-c C-c") #'js-send-buffer)
            (local-set-key (kbd "C-c C-r") #'js-send-region)
            (local-set-key (kbd "C-c C-s") #'js-send-last-sexp)
            (local-set-key (kbd "C-c C-z") #'run-js)
            ;; (flycheck-select-checker 'javascript-jslint-reporter)
            ))

;; (add-hook 'after-init-hook
;;           #'(lambda ()
;;               (when (locate-library "slime-js")
;;                 (require 'setup-slime-js))))

;;; SLIME
;; (require 'slime-autoloads)

;; Set your lisp system and, optionally, some contribs
(setq slime-lisp-implementations
      '((kawa
         ("java"
          ;; needed jar files
          "-cp" "/Users/duncan/bin/kawa.jar:/Users/duncan/bin/swank-kawa.jar:/Library/Java/JavaVirtualMachines/jdk1.8.0_112.jdk/Contents/Home/lib/tools.jar"
          ;; channel for debugger
          "-agentlib:jdwp=transport=dt_socket,server=y,suspend=n"
          ;; depending on JVM, compiler may need more stack
          "-Xss2M"
          ;; kawa without GUI
          "kawa.repl" "-s")
         :init kawa-slime-init)))

(defun kawa-slime-init (file _)
  (setq slime-protocol-version 'ignore)
  (format "%S\n"
          `(begin (import (swank-kawa))
                  (start-swank ,file)
                  ;; Optionally add source paths of your code so
                  ;; that M-. works better:
                  ;;(set! swank-java-source-path
                  ;;  (append
                  ;;   '(,(expand-file-name "~/lisp/slime/contrib/")
                  ;;     "/scratch/kawa")
                  ;;   swank-java-source-path))
                  )))

;; Optionally define a command to start it.
(defun kawa ()
  (interactive)
  (slime 'kawa))

(add-hook 'slime-repl-mode-hook
          (lambda ()
            (paredit-mode +1)
            (define-key slime-repl-mode-map
              (read-kbd-macro paredit-backward-delete-key) nil)))
;; (setq slime-contribs '(inferior-slime slime-repl slime-banner slime-scratch))
(setq slime-contribs '(inferior-slime slime-banner slime-repl slime-scratch))

;;; Python

(add-hook 'python-mode-hook
          (lambda ()
            (subword-mode +1)
            (set-variable 'indent-tabs-mode nil)
            (setq tab-width        4
                  py-indent-offset 4
                  python-indent    4)))

;;; C#
(add-hook 'csharp-mode-hook
          (function (lambda ()
                      (electric-pair-mode -1)
                      (electric-indent-mode -1))))

;;; Coffeescript
(add-hook 'coffee-mode-hook
          (function (lambda ()
                      (setenv "NODE_NO_READLINE" "1")
                      (imenu-add-menubar-index)
                      (make-local-variable 'tab-width)
                      (set 'tab-width 2)
                      (subword-mode t)
                      (electric-indent-mode -1)
                      )))

;;; Ruby
(require 'ruby-mode)
(defun ruby-hook ()
  (imenu-add-menubar-index)
  (subword-mode +1)
  (electric-pair-mode -1)
  (electric-indent-mode -1)
  (require 'pry))

(eval-after-load 'ruby-mode '(add-hook 'ruby-mode-hook 'ruby-hook))
(add-to-list 'auto-mode-alist '("Gemfile" . ruby-mode))
(add-to-list 'auto-mode-alist '("Rakefile" . ruby-mode))
(add-to-list 'auto-mode-alist '("\\.rake$" . ruby-mode))
(add-to-list 'auto-mode-alist '("\\.rb$" . ruby-mode))

;; (add-hook 'inf-ruby-mode-hook
;;           (lambda ()
;;             (require 'inf-ruby-company)
;;             (setq company-idle-delay 0.1)
;;             (setq company-minimum-prefix-length 2)))


;;; Scala
;; (setenv "ENSIME_JVM_ARGS" "-Xms128M -Xmx512M -Dfile.encoding=UTF-8")
;; (require 'ensime)
;; (require 'scala-mode2)
;; (defun scala-hook ()
;;   (subword-mode +1)
;;   (ensime-scala-mode-hook)
;;   (electric-pair-mode -1)
;;   (electric-indent-mode -1)
;;   (setq ensime-sem-high-faces
;;         '(
;;           (var . (:foreground "#ff2222"))
;;           (val . (:foreground "#dddddd"))
;;           (varField . (:foreground "#ff3333"))
;;           (valField . (:foreground "#dddddd"))
;;           (functionCall . (:foreground "#84BEE3"))
;;           (param . (:foreground "#ffffff"))
;;           (class . font-lock-type-face)
;;           (trait . (:foreground "#084EA8"))
;;           (object . (:foreground "#026DF7"))
;;           (package . font-lock-preprocessor-face)
;;           ))
;;   )

;; (add-hook 'scala-mode-hook 'scala-hook)

;;; golden-ratio
;; (require 'golden-ratio)
;; (golden-ratio-enable)

;;; mode line
(require 'telephone-line)
(telephone-line-mode 1)

;;
;; Setup for ediff.
;;
(require 'ediff)

(defvar ediff-after-quit-hooks nil
  "* Hooks to run after ediff or emerge is quit.")

(defadvice ediff-quit (after edit-after-quit-hooks activate)
  (run-hooks 'ediff-after-quit-hooks))

(setq git-mergetool-emacsclient-ediff-active nil)

(defun local-ediff-frame-maximize ()
  (let* ((bounds (display-usable-bounds))
     (x (nth 0 bounds))
     (y (nth 1 bounds))
     (width (/ (nth 2 bounds) (frame-char-width)))
     (height (/ (nth 3 bounds) (frame-char-height))))
    (set-frame-width (selected-frame) width)
    (set-frame-height (selected-frame) height)
    (set-frame-position (selected-frame) x y)))

(setq ediff-window-setup-function 'ediff-setup-windows-plain)
(setq ediff-split-window-function 'split-window-horizontally)

(defun local-ediff-before-setup-hook ()
  (setq local-ediff-saved-frame-configuration (current-frame-configuration))
  (setq local-ediff-saved-window-configuration (current-window-configuration))
  (local-ediff-frame-maximize)
  (if git-mergetool-emacsclient-ediff-active
      (raise-frame)))

(defun local-ediff-quit-hook ()
  (set-frame-configuration local-ediff-saved-frame-configuration)
  (set-window-configuration local-ediff-saved-window-configuration))

(defun local-ediff-suspend-hook ()
  (set-frame-configuration local-ediff-saved-frame-configuration)
  (set-window-configuration local-ediff-saved-window-configuration))

(add-hook 'ediff-before-setup-hook 'local-ediff-before-setup-hook)
(add-hook 'ediff-quit-hook 'local-ediff-quit-hook 'append)
(add-hook 'ediff-suspend-hook 'local-ediff-suspend-hook 'append)

;; Useful for ediff merge from emacsclient.
(defun git-mergetool-emacsclient-ediff (local remote base merged)
  (setq git-mergetool-emacsclient-ediff-active t)
  (if (file-readable-p base)
      (ediff-merge-files-with-ancestor local remote base nil merged)
    (ediff-merge-files local remote nil merged))
  (recursive-edit))

(defun git-mergetool-emacsclient-ediff-after-quit-hook ()
  (exit-recursive-edit))

(add-hook 'ediff-after-quit-hooks 'git-mergetool-emacsclient-ediff-after-quit-hook 'append)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(ansi-color-names-vector
   ["#212526" "#ff4b4b" "#b4fa70" "#fce94f" "#729fcf" "#ad7fa8" "#8cc4ff" "#eeeeec"])
 '(background-color "#042028")
 '(background-mode dark)
 '(blink-cursor-mode nil)
 '(browse-kill-ring-quit-action (quote save-and-restore))
 '(c-basic-offset 8)
 '(coffee-tab-width 4)
 '(column-number-mode t)
 '(comint-process-echoes t)
 '(confirm-kill-emacs (quote y-or-n-p))
 '(cursor-color "#708183")
 '(custom-enabled-themes (quote (wombat)))
 '(custom-safe-themes
   (quote
    ("fb4bf07618eab33c89d72ddc238d3c30918a501cf7f086f2edf8f4edba9bd59f" "1e7e097ec8cb1f8c3a912d7e1e0331caeed49fef6cff220be63bd2a6ba4cc365" "30fe7e72186c728bd7c3e1b8d67bc10b846119c45a0f35c972ed427c45bacc19" "fc5fcb6f1f1c1bc01305694c59a1a861b008c534cae8d0e48e4d5e81ad718bc6" "64c1dadc18501f028b1008a03f315f609d7d29a888e08993c192c07b9c4babc2" "21d9280256d9d3cf79cbcf62c3e7f3f243209e6251b215aede5026e0c5ad853f" default)))
 '(flycheck-highlighting-mode (quote lines))
 '(foreground-color "#708183")
 '(global-undo-tree-mode t)
 '(ibuffer-display-summary nil)
 '(ibuffer-show-empty-filter-groups nil)
 '(indicate-empty-lines t)
 '(inhibit-startup-screen t)
 '(js2-auto-indent-p t)
 '(js2-basic-offset 4)
 '(js2-cleanup-whitespace t)
 '(js2-mirror-mode t)
 '(nxml-child-indent 4)
 '(org-trello-current-prefix-keybinding "C-c o")
 '(package-selected-packages
   (quote
    (geiser telephone-line slime hlinum diff-hl hl-sexp scheme-complete Save-visited-files hippie-expand-slime yaml-mode ws-trim wgrep undo-tree tuareg tagedit ssh-config-mode ssh sr-speedbar smartparens rvm ruby-mode ruby-end ruby-compilation robe redo+ quack puppet-mode pastels-on-dark-theme parenface paredit org-trello org nrepl nav multiple-cursors monokai-theme mic-paren markdown-mode malabar-mode magit lusty-explorer less-css-mode kill-ring-search jump js-comint ioccur igrep ibuffer-vc highlight-parentheses gitty gitignore-mode gitconfig-mode gist gdb-shell full-ack flycheck-color-mode-line find-file-in-project find-file-in-git-repo f esxml ensime elnode elein dired-single dired-isearch dired-details dired-details+ dired+ diff-git deft cssh css-mode csharp-mode crontab-mode company-inf-ruby color-theme-solarized color-file-completion coffee-mode closure-template-html-mode clojurescript-mode clojure-test-mode cljdoc browse-kill-ring applescript-mode align-cljlet ac-nrepl)))
 '(pivotal-api-token "a6b179a9a3f1615a42752fd18d96fbb6")
 '(puppet-indent-level 4)
 '(quack-default-program "kawa")
 '(rcirc-buffer-maximum-lines 10000)
 '(ruby-deep-indent-paren nil)
 '(scroll-conservatively 101)
 '(show-paren-mode t)
 '(show-trailing-whitespace t)
 '(tool-bar-mode nil))

(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(default ((t (:inherit nil :stipple nil :background "#242424" :foreground "#f6f3e8" :inverse-video nil :box nil :strike-through nil :overline nil :underline nil :slant normal :weight normal :height 180 :width normal :foundry "nil" :family "Menlo"))))
 '(c-annotation-face ((t (:foreground "gray")))))
