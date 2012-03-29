;;; monokai-theme-autoloads.el --- automatically extracted autoloads
;;
;;; Code:


;;;### (autoloads nil "monokai-theme" "monokai-theme.el" (20340 1959))
;;; Generated autoloads from monokai-theme.el

(deftheme monokai "\
Monokai color theme")

(let ((monokai-blue-light "#89BDFF") (monokai-gray "#595959") (monokai-gray-darker "#383830") (monokai-gray-darkest "#141411") (monokai-gray-lightest "#595959") (monokai-gray-light "#E6E6E6") (monokai-green "#A6E22A") (monokai-green-light "#A6E22E") (monokai-grey-dark "#272822") (monokai-magenta "#F92672") (monokai-purple "#AE81FF") (monokai-purple-light "#FD5FF1") (monokai-yellow "#E6DB74") (monokai-yellow-dark "#75715E") (monokai-yellow-light "#F8F8F2")) (custom-theme-set-faces 'monokai `(default ((t (:foreground ,monokai-yellow-light :background ,monokai-grey-dark)))) `(cursor ((t (:foreground ,monokai-magenta)))) `(hl-line ((t (:background ,monokai-gray-darkest)))) `(minibuffer-prompt ((t (:foreground ,monokai-yellow-dark)))) `(modeline ((t (:background ,monokai-gray-lightest :foreground ,monokai-gray-light)))) `(region ((t (:background ,monokai-gray-darker)))) `(show-paren-match-face ((t (:background ,monokai-gray-darker)))) `(font-lock-builtin-face ((t (:foreground ,monokai-green)))) `(font-lock-comment-face ((t (:foreground ,monokai-yellow-dark)))) `(font-lock-constant-face ((t (:foreground ,monokai-purple)))) `(font-lock-doc-string-face ((t (:foreground ,monokai-yellow)))) `(font-lock-function-name-face ((t (:foreground ,monokai-green)))) `(font-lock-keyword-face ((t (:foreground ,monokai-magenta)))) `(font-lock-string-face ((t (:foreground ,monokai-yellow)))) `(font-lock-type-face ((t (:foreground ,monokai-blue-light)))) `(font-lock-variable-name-face ((t (:foreground ,monokai-magenta)))) `(font-lock-warning-face ((t (:bold t :foreground ,monokai-purple-light)))) `(cua-rectangle ((t (:background ,monokai-gray-darkest)))) `(ido-first-match ((t (:foreground ,monokai-purple)))) `(ido-only-match ((t (:foreground ,monokai-green)))) `(ido-subdir ((t (:foreground ,monokai-blue-light)))) `(yas/field-highlight-face ((t (:background ,monokai-gray-darker))))))

(when load-file-name (add-to-list 'custom-theme-load-path (file-name-as-directory (file-name-directory load-file-name))))

(provide-theme 'monokai)

;;;***

;;;### (autoloads nil nil ("monokai-theme-pkg.el") (20340 1959 930323))

;;;***

(provide 'monokai-theme-autoloads)
;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; monokai-theme-autoloads.el ends here
