(require 'rcirc)

(setq rcirc-server-alist
      '(("irc.xamarin.com" :port 32000 :nick "duncan" :password "duncan:foobar:xamarin" :full-name "Duncan Mak" :encryption tls)))

(defun-rcirc-command reconnect (arg)
  "Reconnect the server process."
  (interactive "i")
  (if (buffer-live-p rcirc-server-buffer)
      (with-current-buffer rcirc-server-buffer
	(let ((reconnect-buffer (current-buffer))
	      (server (or rcirc-server rcirc-default-server))
	      (port (if (boundp 'rcirc-port) rcirc-port rcirc-default-port))
	      (nick (or rcirc-nick rcirc-default-nick))
	      (channels)
	      (password)
	      (encryption))
	  (dolist (buf (buffer-list))
	    (with-current-buffer buf
	      (when (equal reconnect-buffer rcirc-server-buffer)
		(remove-hook 'change-major-mode-hook
			     'rcirc-change-major-mode-hook)
                (let ((server-plist (cdr (assoc-string server rcirc-server-alist))))
                  (when server-plist
                    (setq channels (plist-get server-plist :channels))
		    (setq password (plist-get server-plist :password))
		    (setq port (plist-get server-plist :port))
		    (setq encryption (plist-get server-plist :encryption))))
		  )))
	  (if process (delete-process process))
	  (rcirc-connect server port nick
			 nil
			 nil
			 channels password encryption)))))

;;; Attempt reconnection at increasing intervals when a connection is
;;; lost.

(defvar rcirc-reconnect-attempts 0)

;;;###autoload
(define-minor-mode rcirc-reconnect-mode
  nil
  nil
  " Auto-Reconnect"
  nil
  (if rcirc-reconnect-mode
      (progn
	(make-local-variable 'rcirc-reconnect-attempts)
	(add-hook 'rcirc-sentinel-hooks
		  'rcirc-reconnect-schedule nil t))
    (remove-hook 'rcirc-sentinel-hooks
		 'rcirc-reconnect-schedule t)))

(defun rcirc-reconnect-schedule (process &optional sentinel seconds)
  (condition-case err
      (when (and (eq 'closed (process-status process))
		 (buffer-live-p (process-buffer process)))
	(with-rcirc-process-buffer process
	  (unless seconds
	    (setq seconds (exp (1+ rcirc-reconnect-attempts))))
	  (rcirc-print
	   process "my-rcirc.el" "ERROR" rcirc-target
	   (format "scheduling reconnection attempt in %s second(s)." seconds) t)
	  (run-with-timer
	   seconds
	   nil
	   'rcirc-reconnect-perform-reconnect
	   process)))
    (error
     (rcirc-print process "RCIRC" "ERROR" nil
		  (format "%S" err) t)))
)

(defun rcirc-reconnect-perform-reconnect (process)
  (when (and (eq 'closed (process-status process))
	     (buffer-live-p (process-buffer process))
	     )
    (with-rcirc-process-buffer process
      (when rcirc-reconnect-mode
	(if (get-buffer-process (process-buffer process))
	    ;; user reconnected manually
	    (setq rcirc-reconnect-attempts 0)
	  (let ((msg (format "attempting reconnect to %s..."
			     (process-name process)
			     )))
	    (rcirc-print process "my-rcirc.el" "ERROR" rcirc-target
			 msg t))
	  ;; remove the prompt from buffers
	  (condition-case err
	      (progn
		(save-window-excursion
		  (save-excursion
		    (rcirc-cmd-reconnect nil)))
		(setq rcirc-reconnect-attempts 0))
	    ((quit error)
	     (incf rcirc-reconnect-attempts)
	     (rcirc-print process "my-rcirc.el" "ERROR" rcirc-target
			  (format "reconnection attempt failed: %s" err)  t)
	     (rcirc-reconnect-schedule process))))))))

(add-hook 'rcirc-mode-hook
          (lambda ()
            (if (string-match (regexp-opt '("irc.xamarin.com"))
                              (buffer-name))
                (rcirc-reconnect-mode 1))
            (rcirc-track-minor-mode 1)
            (require 'arrange-buffers)
            (define-key rcirc-mode-map (kbd "<f7>") '(lambda () (interactive) (arrange-buffers "^#" "rcirc-mode")))))
