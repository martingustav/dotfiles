;; -*- lexical-binding: t; -*-

(setq user-full-name "Martin"
      user-mail-address "me@martingustav.se")

;;; Performance
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(setq gc-cons-threshold (* 50 1000 1000))
(setq read-process-output-max (* 1024 1024))

;; Skip fontification during input
(setq redisplay-skip-fontification-on-input t)

;; Disable bidirectional text scanning
(setq-default bidi-display-reordering 'left-to-right
	      bidi-paragraph-direction 'left-to-right)
(setq bidi-inhibit-bpa t)

;; Increase large file warning threshold
(setq large-file-warning-threshold 100000000)

;;; Persistence
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Save text entered in minibuffer prompts
(setq history-length 25)
(savehist-mode 1)

;; Persist kill ring across sessions
(setq savehist-additional-variables
      '(search-ring regexp-search-ring kill-ring))

;; Save place in files
(save-place-mode 1)

;; Remember recently edited files
(recentf-mode 1)

;;; File Handling
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Make customize-based setting live in the custom.el file
(setq custom-file "~/.config/emacs/custom.el")
(load custom-file 'noerror)

;; Set backup, autosave and lockfiles
;; to live in /tmp
(setq backup-directory-alist
      `((".*" . ,temporary-file-directory))
      auto-save-file-name-transforms
      `((".*" ,temporary-file-directory t))
      lock-file-name-transforms
      `((".*" ,temporary-file-directory t)))

;; Automatically reread files when changed
(setopt auto-revert-avoid-polling t
	auto-revert-interval 5
	auto-revert-check-vc-info t)
(global-auto-revert-mode t)

;; Automatically reload non-file buffers
(setq global-auto-revert-non-file-buffers t)

;; Automatically follow symlinks without prompting
(setq vc-follow-symlinks t)

;; Auto chmod scripts on save
(add-hook 'after-save-hook
	  #'executable-make-buffer-file-executable-if-script-p)

;; Recenter after save-place restores position
(advice-add 'save-place-find-file-hook :after
	    (lambda (&rest _)
	      (when buffer-file-name
		(ignore-errors (recenter)))))

;; Load user-lisp manually if on Emacs older than version 31.1
(when (version< emacs-version "31.1")
  (add-to-list 'load-path (expand-file-name "user-lisp" user-emacs-directory)))

;;; Package Management
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Set package archives
(setq package-archives
      '(("melpa"        . "https://melpa.org/packages/")
	("elpa"         . "https://elpa.gnu.org/packages/")
	("nongnu"       . "https://elpa.nongnu.org/nongnu/")
	("melpa-stable" . "https://stable.melpa.org/packages/")
	("gnu-devel"    . "https://elpa.gnu.org/devel/")
	("nongnu-devel" . "https://elpa.nongnu.org/nongnu-devel/")))

;; Initialize the package manager
(package-initialize)

(setq use-package-always-ensure t
      use-package-verbose t)

;; Defer packages when not launched in daemon mode
(eval-when-compile
  (require 'use-package))

(setq use-package-always-defer (not (daemonp))
      use-package-always-demand (daemonp))

;; Refresh packages when using package-install if last refresh was longer than 24 hours ago
;; Source: https://andreyor.st/posts/2022-07-15-refresh-package-contents-automatically/
(defcustom package-last-refresh-date nil
  "Date and time when package lists have been refreshed.

This variable is then used to check whether
`package-refresh-contents' call is needed before calling
`package-install'. The value of this variable is updated when
`package-refresh-contents' is called.

See `package-refresh-hour-threshold' for the amount of time needed to
trigger a refresh."
  :type 'string
  :group 'package)

(defcustom package-automatic-refresh-threshold 24
  "Amount of hours since last `package-refresh-contents' call
needed to trigger automatic refresh before calling `package-install'."
  :type 'number
  :group 'package)

(define-advice package-install (:before (&rest _) package-refresh-contents-maybe)
  (when (or (null package-last-refresh-date)
	    (> (/ (float-time
		   (time-subtract
		    (date-to-time (format-time-string "%Y-%m-%dT%H:%M"))
		    (date-to-time package-last-refresh-date)))
		  3600)
	       package-automatic-refresh-threshold))
    (package-refresh-contents)))

(define-advice package-refresh-contents (:after (&rest _) update-package-refresh-date)
  (customize-save-variable
   'package-last-refresh-date
   (format-time-string "%Y-%m-%dT%H:%M")))

;; Machine-specific overrides, not tracked in git
(let ((local-file (expand-file-name "local.el" user-emacs-directory)))
  (when (file-exists-p local-file)
    (load local-file)))

;;; System Integration
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Set default browser
(if (eq system-type 'windows-nt)
    ;; Use the OS-registered default browser on Windows instead of
    ;; assuming firefox is on PATH
    (setq browse-url-browser-function 'browse-url-default-windows-browser)
  (setq browse-url-browser-function 'browse-url-generic
	browse-url-generic-program "firefox"))

;; Use Emacs minibuffer for GPG pinentry
(setq epa-pinentry-mode 'loopback
      epg-pinentry-mode 'loopback)

;; Set default alert style to send desktop notifications.
;; libnotify is Linux-only; fall back to a plain message on Windows.
(setq alert-default-style
      (if (eq system-type 'windows-nt) 'message 'libnotify))

;; Copy to system clipboard in terminal
(use-package clipetty
  :diminish
  :if (not (display-graphic-p))
  :hook (after-init . global-clipetty-mode))

;; Copy links to system clipboard in terminal Emacs
(define-advice browse-url
    (:around (orig-fun &rest args) copy-url-if-termainl)
  (if (display-graphic-p)
      (apply orig-fun args)
    (let ((url (nth 0 args)))
      (message "Clipetty link: %s" url)
      (clipetty--emit (clipetty--osc url t)))))

;;; General Behavior
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Map yes and no to y and n
(fset 'yes-or-no-p 'y-or-n-p)

;; Disable visual and audible bell
(setq ring-bell-function 'ignore)

;; Suppress auto revert messages
(setq auto-revert-verbose nil)

;; Automatically kill all active processes when closing Emacs
(setq confirm-kill-processes nil)

;; Use minibuffer whilst in the minibuffer
(setopt enable-recursive-minibuffers t)

;; Ensure new frames are focused
(defun my/focus-new-client-frame ()
  (select-frame-set-input-focus (selected-frame)))

(add-hook 'server-after-make-frame-hook #'my/focus-new-client-frame)

(use-package isearch
  :ensure nil
  :defer t
  :config
  ;; Spawn Occur buffer with current isearch results
  (defun my-occur-from-isearch ()
    (interactive)
    (let ((query (if isearch-regexp
		     isearch-string
		   (regexp-quote isearch-string))))
      (isearch-update-ring isearch-string isearch-regexp)
      (let (search-nonincremental-instead)
	(ignore-errors (isearch-done t t)))
      (occur query)))
  :bind
  (:map isearch-mode-map
	("C-o" . my-occur-from-isearch)))

;; Show number of matches in the minibuffer
(setq isearch-lazy-count t)

;; Faster mark popping
(setq set-mark-command-repeat-pop t)

;; Delete selection on insert
(delete-selection-mode)

;; Save clipboard before killing
(setq save-interprogram-paste-before-kill t)

;; No duplicates in the kill ring
(setq kill-do-not-save-duplicates t)

;; Hide inapplicable commands for current major mode
(setq read-extended-command-predicate #'command-completion-default-include-p)

(setq mouse-wheel-scroll-amount '(1 ((shift) . 1)) ; Scroll line by line
      mouse-wheel-progressive-speed t              ; Keep scroll speed constant
      scroll-conservatively 10                     ; Scroll smoothly near borders
      scroll-margin 5)                             ; Keep lines visible at edges

(defun my/fit-frame-to-monitor (&optional frame)
  "Resize and center FRAME so it fits entirely within its monitor's work area."
  (let* ((frame (or frame (selected-frame)))
	 (workarea (alist-get 'workarea (frame-monitor-attributes frame)))
	 (mon-x (nth 0 workarea))
	 (mon-y (nth 1 workarea))
	 (mon-width (nth 2 workarea))
	 (mon-height (nth 3 workarea))
	 ;; Leave a margin so the frame doesn't touch the screen edges
	 (target-width (round (* mon-width 0.65)))
	 (target-height (round (* mon-height 0.65))))
    (set-frame-size frame target-width target-height t)
    (set-frame-position frame
			(+ mon-x (/ (- mon-width target-width) 2))
			(+ mon-y (/ (- mon-height target-height) 2)))))

(add-hook 'after-make-frame-functions #'my/fit-frame-to-monitor)
(add-hook 'window-setup-hook #'my/fit-frame-to-monitor)

;;; Text
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Clean up unnecessary whitespace on save
(add-hook 'before-save-hook 'whitespace-cleanup)

(set-language-environment "UTF-8")

;; Automatic line breaking
(add-hook 'text-mode-hook 'turn-on-auto-fill)

;; Spell checking
(use-package ispell
  :ensure nil
  :hook ((text-mode . flyspell-mode)
	 (prog-mode . flyspell-prog-mode))
  :bind ("C-c s" . flyspell-check-previous-highlighted-word)
  :config
  (setq ispell-program-name "hunspell"
	ispell-dictionary "sv_SE,en_US")
  ;; ispell-set-spellchecker-params has to be called
  ;; before ispell-hunspell-add-multi-dic will work
  (ispell-set-spellchecker-params)
  ;; On a fresh machine (e.g. Windows, before hunspell + dictionaries
  ;; are installed and DICPATH is set) this would otherwise error on
  ;; every startup, so fail quietly instead.
  (ignore-errors
    (ispell-hunspell-add-multi-dic "sv_SE,en_US")))

(setq rectangle-preview t)

;;; Keybindings
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Easier repeating of commands
(repeat-mode 1)

;; Additional keybinding for M-x
(keymap-global-set "C-c k" 'execute-extended-command)

;; Increase/decrease text scale
(keymap-global-set "C-=" #'text-scale-increase)
(keymap-global-set "C-+" #'text-scale-increase)
(keymap-global-set "C--" #'text-scale-decrease)

;; Make escape quit prompts
(keymap-global-set "<escape>" 'keyboard-escape-quit)

;; Keybind workarounds for terminal Emacs
(define-key key-translation-map (kbd "C-x ,") (kbd "C-x C-;"))
(define-key key-translation-map (kbd "C-c ,") (kbd "C-c C-,"))

(defun my/insert-line-below ()
  "Insert an empty line below the current line."
  (interactive)
  (save-excursion
    (end-of-line)
    (open-line 1)))

(defun my/insert-line-above ()
  "Insert an empty line above the current line."
  (interactive)
  (save-excursion
    (end-of-line 0)
    (open-line 1)))

(keymap-global-set "S-<return>" #'my/insert-line-below)
(keymap-global-set "C-<return>" #'my/insert-line-above)

(keymap-global-set "M-g r" 'recentf)

(keymap-global-set "M-s g" 'grep)
(keymap-global-set "M-s r" 'rgrep)
(keymap-global-set "M-s f" 'find-name-dired)

;; Use vim-like word navigation
(require 'viper-cmd)
(global-set-key (kbd "M-f") 'viper-forward-word)
(global-set-key (kbd "M-b") 'viper-backward-word)

(keymap-global-set "M-o" 'other-window)

;; Window resizing
(keymap-global-set "C-<down>" 'enlarge-window)
(keymap-global-set "C-<up>" 'shrink-window)
(keymap-global-set "C-<left>" 'shrink-window-horizontally)
(keymap-global-set "C-<right>" 'enlarge-window-horizontally)

(keymap-global-set "C-x w s" 'window-swap-states)

;; Keyboard-invoked menus
(use-package casual
  :config
  (casual-init)
  (setq casual-keybinding-primary "C-c o"
	casual-keybinding-secondary "C-c m"))

(add-hook 'outline-minor-mode-hook
	  (lambda ()
	    (keymap-set outline-minor-mode-map "C-c C-n" #'outline-next-visible-heading)
	    (keymap-set outline-minor-mode-map "C-c C-p" #'outline-previous-visible-heading)))

;;; Programming
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package prog-mode
  :ensure nil
  :hook (prog-mode . (lambda ()
		       (subword-mode)
		       (show-paren-mode)
		       (electric-pair-mode))))

;; Git interface
(use-package magit
  :custom
  (magit-display-buffer-function
   #'magit-display-buffer-same-window-except-diff-v1)
  :bind
  ("C-c g" . magit-status))

;; Show Git diff in margin
(use-package git-gutter
  :diminish
  :defer nil
  :config
  (global-git-gutter-mode))

;; Common File Types
(use-package csv-mode)
(use-package ini-mode)
(use-package rasi-mode)

;; Markdown
(if (version<= "31.1" emacs-version)
    (progn
      (with-eval-after-load 'markdown-ts-mode
	(require 'markdown-ts-mode-x))
      (dolist (pat '("\\.md\\'" "\\.mdx\\'" "\\.markdown\\'"))
	(add-to-list 'auto-mode-alist (cons pat 'markdown-ts-mode))))
  (use-package markdown-mode))

;; Generate a table of contents for markdown files
(use-package markdown-toc)

;; Treesitter
(when (version<= "31.1" emacs-version)
    (setopt treesit-auto-install-grammar 'always
	    treesit-enabled-modes t
	    treesit-language-source-alist
	    '((yaml "https://github.com/ikatyang/tree-sitter-yaml")))

  (dolist (mapping '(("\\.sh\\'"          . bash-ts-mode)
		     ("\\.c\\'"           . c-ts-mode)
		     ("\\.h\\'"           . c-ts-mode)
		     ("\\.cpp\\'"         . c++-ts-mode)
		     ("\\.cc\\'"          . c++-ts-mode)
		     ("\\.hpp\\'"         . c++-ts-mode)
		     ("\\.css\\'"         . css-ts-mode)
		     ("\\.html?\\'"       . html-ts-mode)
		     ("\\.java\\'"        . java-ts-mode)
		     ("\\.[cm]?js\\'"     . js-ts-mode)
		     ("\\.json\\'"        . json-ts-mode)
		     ("\\.py[iw]?\\'"     . python-ts-mode)
		     ("\\.ya?ml\\'"       . yaml-ts-mode)))
    (add-to-list 'auto-mode-alist mapping))

  (dolist (lang '(bash c cpp css html java javascript json
		       python yaml))
    (unless (treesit-language-available-p lang)
      (treesit-install-language-grammar lang))))

;;; Completions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package vertico
  :init
  (vertico-mode 1)
  :config
  (setq vertico-scroll-margin 0
	vertico-count 5
	vertico-resize t
	vertico-cycle t))

;; Better completion style.
;; :demand + moving the vars into :config (rather than :custom) means
;; completion-styles only ever gets set to include `orderless' once
;; the package has actually loaded and registered itself in
;; completion-styles-alist; otherwise every minibuffer completion
;; command in Emacs would error with "Invalid completion style".
(use-package orderless
  :demand t
  :config
  (setq completion-styles '(orderless basic)
	completion-category-overrides
	'((file (styles partial-completion)))
	completion-category-defaults nil
	completion-pcm-leading-wildcard t))

;; Completions
(use-package corfu
  :init
  (global-corfu-mode)
  :config
  ;; Use <TAB> for both indentation & completion
  (setq tab-always-indent 'complete
	completion-cycle-threshold 1))

;; Completion extensions
(use-package cape
  :init
  (add-hook 'completion-at-point-functions #'cape-dabbrev)
  (add-hook 'completion-at-point-functions #'cape-abbrev)
  (add-hook 'completion-at-point-functions #'cape-file)
  (add-hook 'completion-at-point-functions #'cape-elisp-block))

;; Annotations for the minibuffer
(use-package marginalia
  :init
  (marginalia-mode 1))

;; More detailed help buffers
(use-package helpful
  :bind (:map helpful-mode-map
	      ("q" . (lambda ()
		       (interactive)
		       (quit-window))))
  :init
  ;; Note that the built-in `describe-function' includes both functions
  ;; and macros. `helpful-function' is functions only, so we provide
  ;; `helpful-callable' as a drop-in replacement.
  (global-set-key (kbd "C-h f") #'helpful-callable)
  (global-set-key (kbd "C-h v") #'helpful-variable)
  (global-set-key (kbd "C-h k") #'helpful-key)
  (global-set-key (kbd "C-h x") #'helpful-command))

(use-package embark
  :config
  ;; Use Embark to help with command discovery
  (setq prefix-help-command #'embark-prefix-help-command))

(use-package nerd-icons-corfu
  :after corfu
  :init
  (add-to-list 'corfu-margin-formatters
	       #'nerd-icons-corfu-formatter))

;;; Windows
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Undo and redo changes in window layout
(winner-mode 1)

;; Make switching buffers more consistent
(setopt switch-to-buffer-obey-display-actions t
	switch-to-buffer-in-dedicated-window 'pop)

;; Automatically switch focus to new window when it is created
(defun my/split-and-follow-horizontally ()
  (interactive)
  (split-window-below)
  (balance-windows)
  (other-window 1))

(global-set-key (kbd "C-x 2") 'my/split-and-follow-horizontally)

(defun my/split-and-follow-vertically ()
  (interactive)
  (split-window-right)
  (balance-windows)
  (other-window 1))

(global-set-key (kbd "C-x 3") 'my/split-and-follow-vertically)

;; Don't open a new window for ediff
(setq ediff-window-setup-function 'ediff-setup-windows-plain)

;; Open man pages in other window
(setq Man-notify-method 'aggressive)

;; Auto focus help-mode windows
(setq help-window-select t)

;; Proportionally resize windows
(setq window-combination-resize t)

;; Reversible <C-x 1>
(defun toggle-delete-other-windows ()
  "Delete other windows in frame if any, or restore previous window config."
  (interactive)
  (if (and winner-mode
	   (equal (selected-window) (next-window)))
      (winner-undo)
    (delete-other-windows)))

(global-set-key (kbd "C-x 1")
		#'toggle-delete-other-windows)

(defun my/select-window (window &rest _)
  "Select WINDOW for display-buffer-alist"
  (select-window window))

;; Settings for displaying buffers
(setq display-buffer-alist
      '(((or . ((derived-mode . occur-mode)))
	 (display-buffer-reuse-mode-window
	  display-buffer-at-bottom)
	 (body-function . my/select-window)
	 (dedicated . t)
	 (preserve-size . (t . t)))

	((or . ((derived-mode . compilation-mode)))
	 (display-buffer-reuse-window
	  display-buffer-same-window)
	 (body-function . my/select-window)
	 (dedicated . t)
	 (inhibit-same-window . nil)
	 (preserve-size . (t . t)))

	((or . ((derived-mode . helpful-mode)))
	 (display-buffer-reuse-mode-window)
	 (mode . helpful-mode)
	 (reusable-frames . visible)
	 (dedicated . t))

	;; Hide compilation windows
	("\\*compilation\\*" display-buffer-no-window
	 (allow-no-window . t))))

;;; UI
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Set default frame dimensions
(add-to-list 'default-frame-alist '(height . 40))
(add-to-list 'default-frame-alist '(width . 90))

;; Show column number in status bar
(column-number-mode)

;; Show fringes
(fringe-mode 8)

;; Hide tab bar if only one tab
(setq tab-bar-show 1)

;; Make line numbers relative
(setq display-line-numbers-type 'relative
      display-line-numbers-width-start t)

;; Display line numbers in the below modes
(dolist (hook '(conf-mode-hook
		prog-mode-hook
		text-mode-hook
		markdown-mode-hook
		org-mode-hook))
  (add-hook hook 'display-line-numbers-mode))

;; Set font.
;; "monospace"/"sans" are fontconfig aliases that only resolve on
;; Linux; Windows needs real installed font family names instead.
(let ((mono-spaced-font
       (if (eq system-type 'windows-nt) "Cascadia Code" "monospace"))
      (proportionately-spaced-font
       (if (eq system-type 'windows-nt) "Segoe UI" "sans")))
  (set-face-attribute 'default nil
		      :family mono-spaced-font
		      :height 115)
  (set-face-attribute 'fixed-pitch nil
		      :family mono-spaced-font
		      :height 1.15)
  (set-face-attribute 'variable-pitch nil
		      :family proportionately-spaced-font
		      :height 1.1))

(defun my/disable-all-themes ()
  "Disable all active themes."
  (dolist (theme custom-enabled-themes)
    (disable-theme theme)))

(defun my/enable-theme (theme)
  "Interactively enable the specified THEME and disable all other themes."
  (interactive
   (list
    (completing-read
     "Choose theme: "
     (mapcar #'symbol-name
	     (custom-available-themes)))))
  (my/disable-all-themes)
  (load-theme (intern theme) t)
  (customize-save-variable 'my-chosen-theme theme))

;; Remember last used theme between sessions,
;; default to modus-operandi-tinted
(defun my/restore-or-default-theme ()
  (unless (boundp 'my-chosen-theme)
    (setq my-chosen-theme "modus-operandi-tinted"))
  (my/enable-theme my-chosen-theme))

(add-hook 'after-init-hook #'my/restore-or-default-theme)

;; Hide minor modes in modeline
(use-package diminish
  :diminish (auto-fill-function
	     centered-window-mode
	     eldoc-mode
	     evil-collection-unimpaired-mode
	     org-indent-mode
	     abbrev-mode
	     flymake-mode
	     hs-minor-mode))

(with-eval-after-load 'subword
  (diminish 'subword-mode))

;; Show full path to file in header line
(defun my/set-header-line-for-files-only ()
  "Set `header-line-format` to show file name info only in file-visiting buffers."
  (setq header-line-format
	(when buffer-file-name
	  (let ((file-name
		 (abbreviate-file-name buffer-file-name)))
	    (concat
	     (propertize file-name
			 'face 'italic))))))

(add-hook 'after-change-major-mode-hook
	  #'my/set-header-line-for-files-only)

;; Visualize color codes in text
(use-package colorful-mode
  :diminish
  :defer nil
  :config
  (global-colorful-mode t))

;; Enable context menu (mouse-click menu)
(dolist (hook '(text-mode-hook
		prog-mode-hook
		dired-mode-hook))
  (add-hook hook 'context-menu-mode))

;; Consider all themes as safe
(setq custom-safe-themes t)

;; Don't render cursors in non-focused windows
(setq-default cursor-in-non-selected-windows nil)
(setq highlight-nonselected-windows nil)

(use-package modus-themes)

;;; Org Mode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package org
  :ensure nil
  :bind (("C-c a"     . org-agenda)
	 ("C-c c"     . org-capture)
	 ("C-c l"     . org-store-link)
	 ("C-c M-RET" . org-insert-todo-heading))
  :config
  ;; org-directory defaults to the personal notes dir, but local.el
  ;; (loaded early in this file, well before org is ever required)
  ;; can set `my/work-org-directory' to point somewhere else on a
  ;; given machine, e.g. a work-only notes folder.
  (setq org-directory (or (bound-and-true-p my/work-org-directory)
			   "~/notes/org")
	org-archive-location (concat org-directory "/arkiv.org::")
	org-todo-keywords '((sequence "TODO" "|" "DONE"))
	org-M-RET-may-split-line '((default . nil))
	org-insert-heading-respect-content t
	org-log-done 'time
	org-log-into-drawer t)

  (load "sv-kalender")

  ;; Refile settings
  (setq org-default-notes-file
	(concat org-directory "/omarkiv.org")
	org-refile-targets
	'(("todo.org"		:maxlevel . 2)
	  ("rep.org"		:maxlevel . 1)
	  ("arkiv.org"		:level    . 0)
	  ("media_arkiv.org"	:maxlevel . 1)
	  ("varia.org"		:maxlevel . 1)
	  ("kalender.org"	:level    . 0))
	org-refile-use-outline-path 'file
	org-outline-path-complete-in-steps nil)

  ;; Appearance
  (setq org-tags-column 0
	org-src-preserve-indentation t
	;; Hide file names in agenda buffer
	org-agenda-prefix-format
	'((agenda . " %i %?-12t% s")
	  (todo   . " %i %-12:c")
	  (tags   . " %i %-12:c")
	  (search . " %i %-12:c"))
	org-ellipsis " ▾"
	;; Empty line before headings
	org-blank-before-new-entry
	'((heading . t)
	  (plain-list-item . nil))
	org-startup-folded "content")

  ;; Make only first org heading be bold
  (custom-set-faces
   '(org-level-1
     ((t (:inherit outline-1
		   :weight bold
		   :height 1.1))))
   '(org-level-2
     ((t (:inherit outline-2
		   :weight normal))))
   '(org-level-3
     ((t (:inherit outline-3
		   :weight normal))))
   '(org-level-4
     ((t (:inherit outline-4
		   :weight normal))))
   '(org-level-5
     ((t (:inherit outline-5
		   :weight normal))))
   '(org-level-6
     ((t (:inherit outline-6
		   :weight normal))))
   '(org-level-7
     ((t (:inherit outline-7
		   :weight normal))))
   '(org-level-8
     ((t (:inherit outline-8
		   :weight normal))))))

;; Generate a table of contents
(use-package toc-org
  :hook (org-mode . toc-org-mode))

(use-package org-agenda
  :ensure nil
  :after org
  :config
  (setq org-agenda-span 'day
	org-agenda-tags-column 0
	org-agenda-start-on-weekday nil
	org-agenda-skip-scheduled-if-deadline-is-shown t
	org-agenda-skip-deadline-if-done t
	org-agenda-skip-scheduled-if-done t
	org-agenda-todo-list-sublevels t
	org-agenda-files
	(seq-remove
	 (lambda (f) (string= (file-name-nondirectory f) "arkiv.org"))
	 (directory-files org-directory t "\\.org\\'"))

	;; Time grid settings
	org-agenda-time-grid
	'((daily today require-timed remove-match)
	  (800 1000 1200 1400 1600 1800 2000)
	  "...."
	  "------------")
	org-agenda-current-time-string "← now")

  (setq org-agenda-custom-commands
	'(("w" "Week agenda"
	   ((agenda ""
		    ((org-agenda-span 'week)))))
	  ("k" "Month agenda"
	   ((agenda ""
		    ((org-agenda-span 'month)))))))

  ;; Date heading settings
  (custom-set-faces
   '(org-agenda-date
     ((t (:height 1.0
		  :weight bold
		  :background unspecified))))
   '(org-agenda-date-today
     ((t (:height 1.3
		  :weight bold
		  :background unspecified
		  :underline unspecified)))))

  (add-hook 'org-agenda-finalize-hook (lambda () (goto-char (point-min))) 90))

(use-package org-capture
  :ensure nil
  :after org
  :config
  ;; Don't save org capture bookmarks
  (setq org-bookmark-names-plist nil
	org-capture-bookmark nil)
  :custom
  ;; my/org-capture-inbox-file lets local.el redirect where Task/Note
  ;; captures land on a given machine (e.g. straight to todo.org
  ;; instead of the personal omarkiv.org inbox).
  (org-capture-templates
   (let ((inbox (or (bound-and-true-p my/org-capture-inbox-file) "omarkiv.org")))
     (append
      `(("t" "Task" entry (file ,inbox)
	 "* TODO %?\n%i\n")

	("l" "Task with link" entry (file ,inbox)
	 "* TODO %?\n%i\n%a")

	("n" "Note" entry (file ,inbox)
	 "* %?\n%i\n")

	("e" "Calendar event" entry (file "kalender.org")
	 "* %?\n%^t"))
      (unless (bound-and-true-p my/disable-org-contacts)
	'(("c" "Contact" entry (file "kontakter.org")
	   "* %? \n:PROPERTIES:\n:PHONE: %^{Phone number}\n:END:")))))))

(unless (bound-and-true-p my/disable-org-contacts)
  (use-package org-contacts
    :after org
    :pin melpa
    :custom
    (org-contacts-files (list (expand-file-name "kontakter.org" org-directory)))))

(use-package org-wild-notifier
  :config
  (org-wild-notifier-mode)
  (setq org-wild-notifier-day-wide-alert-times
	'("07:00")))

(defun my/org-review-inboxes ()
  (interactive)
  (find-file (expand-file-name "omarkiv.org" org-directory))
  (delete-other-windows)
  (split-window-right)
  (find-file-other-window (expand-file-name "mob_omarkiv.org" org-directory))
  (other-window 1)
  (beginning-of-buffer)
  (org-next-visible-heading 1))

;;; Misc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; vterm needs a compiled native module (cmake/libtool/a C toolchain)
;; that's a pain to set up on Windows, so it's skipped there entirely.
;; Wrapping in `unless' rather than relying on :if/:ensure keyword
;; semantics, since :ensure doesn't accept an arbitrary expression and
;; :if alone doesn't reliably prevent package-install from running.
(unless (eq system-type 'windows-nt)
  (use-package vterm
    :custom
    (term-prompt-regexp "^[^#$%>\n]*[#$%>] *")
    (vterm-shell "zsh")
    (vterm-max-scrollback 10000))

  ;; Open multiple vterm buffers
  (use-package multi-vterm
    :bind
    ("C-c T" . multi-vterm-dedicated-toggle)
    ("C-c t" . multi-vterm)
    :config
    (setq multi-vterm-dedicated-window-height-percent 30)))

;; Fall back to eshell on the same keybinding where vterm is
;; unavailable
(when (eq system-type 'windows-nt)
  (keymap-global-set "C-c t" #'eshell))

(use-package dired
  :ensure nil
  :hook (dired-mode . dired-hide-details-mode)
  :bind
  (:map dired-mode-map
	("b" . dired-up-directory))
  :custom
  ;; Show in long listing format,
  ;; show hidden files,
  ;; show sizes in human-readable format
  ;; sort directories first,
  ;; use natural sort for version numbers within text
  (dired-listing-switches
   "-lAhv --group-directories-first")
  ;; No infinite dired buffers!
  (dired-kill-when-opening-new-dired-buffer t))

(use-package dired-open)

(use-package auctex
  :config
  (setq TeX-auto-save t
	TeX-parse-self t
	TeX-view-program-selection
	'((output-pdf "PDF Tools"))
	TeX-view-program-list
	'(("PDF Tools"
	   TeX-pdf-tools-sync-view))
	TeX-source-correlate-start-server t
	TeX-source-correlate-mode 1)
  (add-hook 'TeX-after-compilation-finished-functions
	    #'TeX-revert-document-buffer))

(use-package pdf-tools
  :config
  (add-to-list 'auto-mode-alist '("\\.pdf\\'" . pdf-view-mode)))

;; Local Variables:
;; outline-minor-mode-cycle: t
;; outline-regexp: ";;; "
;; eval: (outline-minor-mode)
;; eval: (outline-hide-body)
;; End:
