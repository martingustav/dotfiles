;;;; Run commands in a popup frame  -*- lexical-binding: t; -*-

(defun prot-window-delete-popup-frame (&rest _)
  "Kill selected selected frame if it has parameter `prot-window-popup-frame'.
Use this function via a hook."
  (when (frame-parameter nil 'prot-window-popup-frame)
    (delete-frame)))

(defun prot-window--graphical-display ()
  "Return the name of the graphical display to open a frame on, or nil."
  (cond
   ;; Native MS-Windows build: there is a single display called "w32".
   ((eq system-type 'windows-nt) "w32")
   ;; Pure GTK build (native Wayland); also works under X if that is all there is.
   ((featurep 'pgtk) (or (getenv "WAYLAND_DISPLAY") (getenv "DISPLAY")))
   ;; Lucid/GTK3-on-X build: on Wayland this goes through XWayland.
   (t (getenv "DISPLAY"))))

(defun prot-window--make-popup-frame (parameters)
  "Return a new graphical frame with PARAMETERS.
Work even when called from a daemon that has no graphical frame yet,
where `make-frame' would otherwise inherit the daemon's placeholder
terminal and fail."
  (if (seq-some #'display-graphic-p (frame-list))
      (make-frame parameters)
    (if-let* ((display (prot-window--graphical-display)))
	(make-frame-on-display display parameters)
      (user-error "No graphical display found in the daemon's environment"))))

(defmacro prot-window-define-with-popup-frame (command)
  "Define interactive function which calls COMMAND in a new frame.
Make the new frame have the `prot-window-popup-frame' parameter."
  `(defun ,(intern (format "prot-window-popup-%s" command)) ()
     ,(format "Run `%s' in a popup frame with `prot-window-popup-frame' parameter.
Also see `prot-window-delete-popup-frame'." command)
     (interactive)
     (let ((frame (prot-window--make-popup-frame '((prot-window-popup-frame . t)))))
       (select-frame frame)
       (switch-to-buffer " prot-window-hidden-buffer-for-popup-frame")
       (condition-case nil
	   (call-interactively ',command)
	 ((quit error user-error)
	  (delete-frame frame))))))

(declare-function org-capture "org-capture" (&optional goto keys))
(defvar org-capture-after-finalize-hook)

;;;###autoload (autoload 'prot-window-popup-org-capture "prot-window-popup" nil t)
(prot-window-define-with-popup-frame org-capture)

(add-hook 'org-capture-after-finalize-hook #'prot-window-delete-popup-frame)

(provide 'prot-window-popup)
;;; prot-window-popup.el ends here
