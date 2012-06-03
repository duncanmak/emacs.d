(server-start)
(load-theme 'tango-dark t)
(desktop-save-mode 1)
(setq-default indent-tabs-mode nil)
(let ((default-directory "~/.emacs.d/site-lisp/"))
  (normal-top-level-add-to-load-path '("."))
  (normal-top-level-add-subdirs-to-load-path))

(global-undo-tree-mode)

;;; Mac specific
(when (eq system-type 'darwin)
  (require 'ls-lisp)
  (setq ls-lisp-use-insert-directory-program nil)
  (setq mac-command-key-is-meta t)
  (setq mac-command-modifier 'meta)
  (setq mac-option-key-is-meta nil)
  (setq mac-option-modifier nil)
  (setenv "PATH" (concat "/usr/local/bin:" (getenv "PATH")))
  (push "/usr/local/bin" exec-path)
  (global-set-key "\M-`" 'other-frame)
  (set-face-attribute 'default nil :family "Menlo" :height 140)
  )

;;; Linux specific
(when (eq system-type 'gnu/linux)
  (setenv "PATH" (concat (getenv "PATH") ":/home/duncan/bin"))
  (setq ack-executable "ack-grep")
  (set-face-attribute 'default nil :family "Droid Sans Mono" :height 100))

;;; Windows specific
(when (eq system-type 'windows-nt)
  (push "C:\\Program Files (x86)\\Git\\bin" exec-path)
  (set-face-attribute 'default nil :family "Consolas" :height 120))

;;; windmove
(global-set-key (kbd "C-c <left>")  'windmove-left)
(global-set-key (kbd "C-c <right>") 'windmove-right)
(global-set-key (kbd "C-c <up>")    'windmove-up)
(global-set-key (kbd "C-c <down>")  'windmove-down)

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

(add-hook 'before-save-hook 'delete-trailing-whitespace)

;;; iswitchb
(require 'iswitchb)
(add-to-list 'iswitchb-buffer-ignore "^ ")
(add-to-list 'iswitchb-buffer-ignore "*Messages*")
(add-to-list 'iswitchb-buffer-ignore "*ECB")
(add-to-list 'iswitchb-buffer-ignore "*Buffer")
(add-to-list 'iswitchb-buffer-ignore "*Completions")
(add-to-list 'iswitchb-buffer-ignore "*ftp ")
(add-to-list 'iswitchb-buffer-ignore "*bsh")
(add-to-list 'iswitchb-buffer-ignore "*jde-log")
(add-to-list 'iswitchb-buffer-ignore "^[tT][aA][gG][sS]$")
(add-to-list 'iswitchb-buffer-ignore "@")
(defun iswitchb-local-keys ()
  (mapc (lambda (K)
          (let* ((key (car K)) (fun (cdr K)))
            (define-key iswitchb-mode-map (edmacro-parse-keys key) fun)))
        '(("<right>" . iswitchb-next-match)
          ("<left>"  . iswitchb-prev-match)
          ("<up>"    . ignore             )
          ("<down>"  . ignore             ))))
(add-hook 'iswitchb-define-mode-map-hook 'iswitchb-local-keys)

;;; ibuffer
(global-set-key (kbd "C-x C-b") 'ibuffer)
(autoload 'ibuffer "ibuffer" "List buffers." t)
(add-hook 'ibuffer-hook
	  (lambda ()
	    (ibuffer-vc-set-filter-groups-by-vc-root)
	    (ibuffer-do-sort-by-alphabetic)
            (setq ibuffer-formats
                  '((mark modified read-only vc-status-mini " "
                          (name 18 18 :left :elide)
                          " "
                          (size 9 -1 :right)
                          " "
                          (mode 16 16 :left :elide)
                          " "
                          (vc-status 16 16 :left)
                          " "
                          filename-and-process)))
            ))

;; Make control+pageup/down scroll the other buffer
(global-set-key [C-next]  'scroll-other-window)
(global-set-key [C-prior] 'scroll-other-window-down)

;; stops selection with a mouse being immediately injected to the kill ring
(setq mouse-drag-copy-region nil)
;; makes killing/yanking interact with clipboard X11 selection
(setq x-select-enable-clipboard t)

;; Make all "yes or no" prompts show "y or n" instead
(fset 'yes-or-no-p 'y-or-n-p)

(global-set-key (kbd "C-x g") 'magit-status)

(delete-selection-mode t)
(show-paren-mode t)

(defun lisp-hook ()
  (require 'paredit)
  (require 'eldoc) ; if not already loaded
  (turn-on-eldoc-mode)
  (imenu-add-menubar-index)
  (eldoc-add-command
   'paredit-backward-delete
   'paredit-close-round)
  (paredit-mode +1)
  (define-key paredit-mode-map (kbd "RET") 'paredit-newline)
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

;;; dired
(require 'dired)
(defun my-dired-init ()
  "Bunch of stuff to run for dired, either immediately or when it's
        loaded."
  ;; <add other stuff here>
  (define-key dired-mode-map [return] 'dired-single-buffer)
  (define-key dired-mode-map [mouse-1] 'dired-single-buffer-mouse)
  (define-key dired-mode-map "^"
    (function
     (lambda nil (interactive) (dired-single-buffer "..")))))

;; if dired's already loaded, then the keymap will be bound
(if (boundp 'dired-mode-map)
    ;; we're good to go; just add our bindings
    (my-dired-init)
  ;; it's not loaded yet, so add our bindings to the load-hook
  (add-hook 'dired-load-hook 'my-dired-init))
(global-set-key [(f5)] 'dired-single-magic-buffer)
(global-set-key [(control f5)] (function
				(lambda nil (interactive)
				  (dired-single-magic-buffer default-directory))))
(global-set-key [(shift f5)] (function
			      (lambda nil (interactive)
				(message "Current directory is: %s" default-directory))))
(global-set-key [(meta f5)] 'dired-single-toggle-buffer-name)
(define-key dired-mode-map (kbd "C-s") 'dired-isearch-forward)
(define-key dired-mode-map (kbd "C-r") 'dired-isearch-backward)
(define-key dired-mode-map (kbd "ESC C-s") 'dired-isearch-forward-regexp)
(define-key dired-mode-map (kbd "ESC C-r") 'dired-isearch-backward-regexp)

(add-hook 'dired-load-hook (function (lambda () (setq dired-x-hands-off-my-keys nil) (load "dired-x"))))
(define-key global-map (kbd "C-x C-j") 'dired-jump)

(defun c-hook ()
  (imenu-add-menubar-index)
  (subword-mode +1)
  (electric-pair-mode +1)
  (electric-indent-mode +1))

;;; java
(add-hook 'java-mode-hook 'c-hook)

;;; javascript
(autoload 'js2-mode "js2-mode" nil t)
(add-to-list 'auto-mode-alist '("\\.js$" . js2-mode))

;;; Python

(add-hook 'python-mode-hook
          (lambda ()
            (subword-mode +1)
            (setq indent-tabs-mode t
                  tab-width        2
                  py-indent-offset 2
                  python-indent    2)))

;;; C#
(add-hook 'csharp-mode-hook
          (function (lambda ()
                      (electric-pair-mode -1)
                      (electric-indent-mode -1)
                      (require 'flymake))))

;;; Coffeescript
(add-to-list 'load-path "coffee-mode")
(require 'coffee-mode)
(add-hook 'coffee-mode-hook
          (function (lambda ()
                      (imenu-add-menubar-index)
                      (setenv "NODE_NO_READLINE" "1")
                      (set (make-local-variable 'tab-width) 2)
                      (subword-mode t)
                      )))

;;; Ruby
(defun ruby-hook ()
  (add-to-list 'load-path "rinari")
  (require 'rinari)
  (add-to-list 'load-path "rvm")
  (require 'rvm)
  (add-to-list 'load-path "ruby-debug-extra/emacs")
  (require 'rdebug)
  (rinari-launch)
  (imenu-add-menubar-index)
  (inf-ruby-keys)
  (subword-mode +1)
  (electric-pair-mode -1)
  (electric-indent-mode -1)
  (ruby-electric-mode)
  (ad-activate 'run-ruby))

(defadvice run-ruby (after rvm-run-ruby-advice)
  "Activate RVM when run-ruby"
  (rvm-activate-corresponding-ruby))

(eval-after-load 'ruby-mode '(add-hook 'ruby-mode-hook 'ruby-hook))
(add-to-list 'auto-mode-alist '("Gemfile" . ruby-mode))
(add-to-list 'auto-mode-alist '("Rakefile" . ruby-mode))
(add-to-list 'auto-mode-alist '("\\.rake$" . ruby-mode))
(add-to-list 'auto-mode-alist '("\\.rb$" . ruby-mode))

;;; Scala
(add-to-list 'load-path "ensime/elisp/")
(setenv "ENSIME_JVM_ARGS" "-Xms128M -Xmx512M -Dfile.encoding=UTF-8")
(require 'ensime)

(defun scala-hook ()
  (subword-mode +1)
  (ensime-scala-mode-hook)
  (electric-pair-mode -1)
  (electric-indent-mode -1)
  (scala-electric-mode +1)
  (setq ensime-sem-high-faces
        '(
          (var . (:foreground "#ff2222"))
          (val . (:foreground "#dddddd"))
          (varField . (:foreground "#ff3333"))
          (valField . (:foreground "#dddddd"))
          (functionCall . (:foreground "#84BEE3"))
          (param . (:foreground "#ffffff"))
          (class . font-lock-type-face)
          (trait . (:foreground "#084EA8"))
          (object . (:foreground "#026DF7"))
          (package . font-lock-preprocessor-face)
          ))
  )

(add-hook 'scala-mode-hook 'scala-hook)

;;; rcirc
(eval-after-load 'rcirc
  '(defun-rcirc-command reconnect (arg)
     "Reconnect the server process."
     (interactive "i")
     (unless process
       (error "There's no process for this target"))
     (let* ((server (car (process-contact process)))
            (port (process-contact process :service))
            (nick (rcirc-nick process))
            (password (read-passwd "IRC Password: "))
            channels query-buffers)
       (dolist (buf (buffer-list))
         (with-current-buffer buf
           (when (eq process (rcirc-buffer-process))
             (remove-hook 'change-major-mode-hook
                          'rcirc-change-major-mode-hook)
             (if (rcirc-channel-p rcirc-target)
                 (setq channels (cons rcirc-target channels))
               (setq query-buffers (cons buf query-buffers))))))
       (delete-process process)
       (rcirc-connect server port nick
                      rcirc-default-user-name
                      rcirc-default-user-full-name
                      channels password))))

(add-hook 'rcirc-mode-hook
          (lambda ()
            (rcirc-track-minor-mode 1)
            (require 'arrange-buffers)
            (define-key rcirc-mode-map (kbd "<f7>") '(lambda () (interactive) (arrange-buffers "^#" "rcirc-mode")))))

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(blink-cursor-mode nil)
 '(browse-kill-ring-quit-action (quote save-and-restore))
 '(column-number-mode t)
 '(comint-process-echoes t)
 '(confirm-kill-emacs (quote y-or-n-p))
 '(custom-enabled-themes (quote (tango-dark)))
 '(custom-safe-themes (quote ("64c1dadc18501f028b1008a03f315f609d7d29a888e08993c192c07b9c4babc2" "21d9280256d9d3cf79cbcf62c3e7f3f243209e6251b215aede5026e0c5ad853f" default)))
 '(display-time-mode t)
 '(ibuffer-display-summary nil)
 '(indicate-empty-lines t)
 '(inhibit-startup-screen t)
 '(iswitchb-max-to-show 10)
 '(iswitchb-mode t)
 '(iswitchb-use-virtual-buffers t nil (recentf))
 '(js2-auto-indent-p t)
 '(js2-cleanup-whitespace t)
 '(js2-mirror-mode t)
 '(pivotal-api-token "a6b179a9a3f1615a42752fd18d96fbb6")
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
 '(c-annotation-face ((t (:foreground "gray")))))

(require 'package)
;; Add the original Emacs Lisp Package Archive
(add-to-list 'package-archives
             '("elpa" . "http://tromey.com/elpa/"))
;; Add the user-contributed repository
(add-to-list 'package-archives
             '("marmalade" . "http://marmalade-repo.org/packages/"))
