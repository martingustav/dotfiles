;; -*- lexical-binding: t; -*-

;; Increase garbace collection threshold temporarily
(setq gc-cons-threshold 100000000)

;; Prevent Emacs from initializing package manager,
;; as I do that later on manually
(setq package-enable-at-startup nil)

;; Unset file-name-handler-alist temporarily
(defvar file-name-handler-alist-original file-name-handler-alist)
(setq file-name-handler-alist nil)

;; Restore original file-name-handler-alist after initialization
(add-hook 'after-init-hook
	  (lambda () (setq file-name-handler-alist file-name-handler-alist-original)))

;; Hide UI elements
(setq initial-scratch-message nil)
(tool-bar-mode -1)
(blink-cursor-mode -1)
(setq visible-cursor nil)

;; Hide scroll bar in minibuffer
(add-hook 'after-make-frame-functions
	  (lambda (frame)
	    (set-window-scroll-bars
	     (minibuffer-window frame) 0 nil 0 nil t)))

;; Don't show unnecessary warnings
(setq warning-minimum-level :error
      byte-compile-warnings '(not obsolete)
      warning-suppress-log-types '((comp) (bytecomp))
      native-comp-async-report-warnings-errors 'silent)

(setq frame-resize-pixelwise t)
