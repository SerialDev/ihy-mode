;;; ihy.el --- Ihy minor mode for Hy Repl support

;; Copyright (C) 2018 Andres Mariscal

;; Author: Andres Mariscal <carlos.mariscal.melgar@gmail.com>
;; Created: 1 May 2018
;; Version: 0.0.1
;; Keywords: hy languages repl
;; URL: https://github.com/serialdev/ihy-mode
;; Package-Requires: ((emacs "24.3", hy-mode ))
;;; Commentary:
;; Hy Repl support through ihy repl

;; Usage


(defun get-last-sexp (&optional bounds)
  "Return the sexp preceding the point."
  (interactive)
  (let ((points     (save-excursion
           (list (point)
                 (progn (backward-sexp 1)
                        (skip-chars-forward "[:blank:]")
                        (when (looking-at-p "\n") (forward-char 1))
                        (point)))) ))
    (buffer-substring-no-properties  (car points) (cadr points) )
  ))


(defun ihy-eval-last-sexp (begin end)
  "Evaluate last sexp."
  (interactive "r")
  (ihy t)
  (progn
    (maintain-indentation (ihy-split "\n"
				      (get-last-sexp)) 0)
    (comint-send-string ihy-shell-buffer-name ";\n")
  ))

(defun regex-match ( regex-string string-search match-num )
  (string-match regex-string string-search)
  (match-string match-num string-search))


(defcustom ihy-shell-buffer-name "*Ihy*"
  "Name of buffer for ihy."
  :group 'ihy
  :type 'string)

(defun ihy-is-running? ()
  "Return non-nil if ihy is running."
  (comint-check-proc ihy-shell-buffer-name))
(defalias 'ihy-is-running-p #'ihy-is-running?)

;;;###autoload
(defun ihy (&optional arg)
  "Run ihy.
Unless ARG is non-nil, switch to the buffer."
  (interactive "P")
  (let ((buffer (get-buffer-create ihy-shell-buffer-name)))
    (unless arg
      (pop-to-buffer buffer))
    (unless (ihy-is-running?)
      (with-current-buffer buffer
        (ihy-startup)
        (inferior-ihy-mode)
	)
      (pop-to-buffer buffer)
      (other-window -1)
      )
    ;; (with-current-buffer buffer (inferior-ihy-mode))
    buffer))



;;;###autoload
(defalias 'run-hy #'ihy)
;;;###autoload
(defalias 'inferior-hy #'ihy)


(defun ihy-startup ()
  "Start ihy."
  (comint-exec ihy-shell-buffer-name "ihy" ihy-program nil ihy-args))

(defun maintain-indentation (current previous-indent)
  (when current
    (let ((current-indent (length (ihy-match-indentation (car current)))))
      (if (< current-indent previous-indent)
	  (progn
	    (comint-send-string ihy-shell-buffer-name "\n")
	    (comint-send-string ihy-shell-buffer-name (car current))
	    (comint-send-string ihy-shell-buffer-name "\n"))
      (progn
	(comint-send-string ihy-shell-buffer-name (car current))
	(comint-send-string ihy-shell-buffer-name "\n")))
      (maintain-indentation (cdr current) current-indent)
      )))

(defun ihy-split (separator s &optional omit-nulls)
  "Split S into substrings bounded by matches for regexp SEPARATOR.
If OMIT-NULLS is non-nil, zero-length substrings are omitted.
This is a simple wrapper around the built-in `split-string'."
  (declare (side-effect-free t))
  (save-match-data
    (split-string s separator omit-nulls)))


(defun ihy-match-indentation(data)
  (regex-match "^[[:space:]]*" data 0))


(defun ihy-eval-region (begin end)
  "Evaluate region between BEGIN and END."
  (interactive "r")
  (ihy t)
  (progn
    (maintain-indentation (ihy-split "\n"
				      (buffer-substring-no-properties begin end)) 0)
    (comint-send-string ihy-shell-buffer-name ";\n")
  ))



(defun ihy-parent-directory (dir)
  (unless (equal "/" dir)
    (file-name-directory (directory-file-name dir))))

(defun ihy-find-file-in-hierarchy (current-dir fname)
  "Search for a file named FNAME upwards through the directory hierarchy, starting from CURRENT-DIR"
  (let ((file (concat current-dir fname))
        (parent (ihy-parent-directory (expand-file-name current-dir))))
    (if (file-exists-p file)
        file
      (when parent
        (ihy-find-file-in-hierarchy parent fname)))))


(defun ihy-get-string-from-file (filePath)
  "Return filePath's file content.
;; thanks to “Pascal J Bourguignon” and “TheFlyingDutchman 〔zzbba…@aol.com〕”. 2010-09-02
"
  (with-temp-buffer
    (insert-file-contents filePath)
    (buffer-string)))


(defun ihy-eval-buffer ()
  "Evaluate complete buffer."
  (interactive)
  (ihy-eval-region (point-min) (point-max)))

(defun ihy-eval-line (&optional arg)
  "Evaluate current line.
If ARG is a positive prefix then evaluate ARG number of lines starting with the
current one."
  (interactive "P")
  (unless arg
    (setq arg 1))
  (when (> arg 0)
    (ihy-eval-region
     (line-beginning-position)
     (line-end-position arg))))


;;; Shell integration

(defcustom ihy-shell-interpreter "ihy"
  "default repl for shell"
  :type 'string
  :group 'ihy)

(defcustom ihy-shell-internal-buffer-name "Ihy Internal"
  "Default buffer name for the internal process"
  :type 'string
  :group 'hy
  :safe 'stringp)


(defcustom ihy-shell-prompt-regexp "=> "
  "Regexp to match prompts for ihy.
   Matchint top\-level input prompt"
  :group 'ihy
  :type 'regexp
  :safe 'stringp)

(defcustom ihy-shell-prompt-block-regexp " "
  "Regular expression matching block input prompt"
  :type 'string
  :group 'ihy
  :safe 'stringp)

(defcustom ihy-shell-prompt-output-regexp ""
  "Regular Expression matching output prompt of evxcr"
  :type 'string
  :group 'ihy
  :safe 'stringp)

(defcustom ihy-shell-enable-font-lock t
  "Should syntax highlighting be enabled in the ihy shell buffer?"
  :type 'boolean
  :group 'ihy
  :safe 'booleanp)

(defcustom ihy-shell-compilation-regexp-alist '(("[[:space:]]\\^+?"))
  "Compilation regexp alist for inferior ihy"
  :type '(alist string))

(defgroup ihy nil
  "Hy interactive mode"
  :link '(url-link "https://github.com/serialdev/ihy-mode")
  :prefix "ihy"
  :group 'languages)

(defcustom ihy-program (executable-find "hy")
  "Program invoked by `ihy'."
  :group 'ihy
  :type 'file)


(defcustom ihy-args nil
  "Command line arguments for `ihy-program'."
  :group 'ihy
  :type '(repeat string))



(defcustom ihy-prompt-read-only t
  "Make the prompt read only.
See `comint-prompt-read-only' for details."
  :group 'ihy
  :type 'boolean)

(defun ihy-comint-output-filter-function (output)
  "Hook run after content is put into comint buffer.
   OUTPUT is a string with the contents of the buffer"
  (ansi-color-filter-apply output))



(define-derived-mode inferior-ihy-mode comint-mode "Ihy"
  (setq comint-process-echoes t)
  ;; (setq comint-prompt-regexp (format "^\\(?:%s\\|%s\\)"
  ;; 				     ihy-shell-prompt-regexp
  ;; 				     ihy-shell-prompt-block-regexp))
  (setq comint-prompt-regexp "=> ")

  (setq mode-line-process '(":%s"))
  (make-local-variable 'comint-output-filter-functions)
  (add-hook 'comint-output-filter-functions
  	    'ihy-comint-output-filter-function)
  (set (make-local-variable 'compilation-error-regexp-alist)
       ihy-shell-compilation-regexp-alist)
  (setq comint-use-prompt-regexp t)
  (setq comint-inhibit-carriage-motion nil)
  (setq-local comint-prompt-read-only ihy-prompt-read-only)
  (when ihy-shell-enable-font-lock
    (set-syntax-table hy-mode-syntax-table)
    (set (make-local-variable 'font-lock-defaults)
	 '(hy-mode-font-lock-keywords nil nil nil nil))
    (set (make-local-variable 'syntax-propertize-function)
    	 (eval
    	  "Unfortunately eval is needed to make use of the dynamic value of comint-prompt-regexp"
    	  '(syntax-propertize-rules
    	    '(comint-prompt-regexp
    	       (0 (ignore
    		   (put-text-property
    		    comint-last-input-start end 'syntax-table
    		    python-shell-output-syntax-table)
    		   (font-lock-unfontify--region comint-last-input-start end))))
    	    )))
    (compilation-shell-minor-mode 1)))

(progn
  (define-key hy-mode-map (kbd "C-c C-b") #'ihy-eval-buffer)
  (define-key hy-mode-map (kbd "C-c C-r") #'ihy-eval-region)
  (define-key hy-mode-map (kbd "C-c C-l") #'ihy-eval-line)
  (define-key hy-mode-map (kbd "C-c C-s") #'ihy-eval-last-sexp)
  (define-key hy-mode-map (kbd "C-c C-p") #'ihy))

;;;###autoload

(provide 'ihy)

;;; ihy.el ends here
