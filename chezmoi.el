;;; chezmoi.el --- chezmoi management
;;; Commentary:
;;; Some simple commands for working with chezmoi.
;;; Code:

(defconst chezmoi-output-buffer-name "*chezmoi output*")

(defun chezmoi-source-path (file)
  "Get the path to the source for configuration file FILE."
  (interactive "fConfig file: ")
  (let ((chezmoi-file
	 (string-trim
	 (shell-command-to-string
	  (concat "chezmoi source-path " file)))))
    (cond ((file-exists-p chezmoi-file)
	   (progn
	     (when (called-interactively-p 'any)
		 (message (concat "chezmoi source file: " chezmoi-file)))
	     chezmoi-file
	     ))
	  (t (error "Unable to find config file: %s\n %s" file chezmoi-file))
	  )
    )
  )

(defun chezmoi-edit (file)
  "Edit a file managed by chezmoi.
This function should work just like `chezmoi edit'
FILE points to the destination file."
  (interactive "fConfig file: ")
  (let ((chezmoi-file
	 (chezmoi-source-path file)))
    (find-file chezmoi-file)))

(defun chezmoi-apply ()
  "Apply chezmoi config."
  (interactive)
  (start-process "chezmoi apply"
		 chezmoi-output-buffer-name
		 "chezmoi" "apply" "--verbose"))

(defun chezmoi-apply-dry-run ()
  "Show configuration changes in the chezmoi output buffer."
  (interactive)
  (start-process "chezmoi apply dry run"
		 chezmoi-output-buffer-name
		 "chezmoi" "apply" "--dry-run" "--verbose"))

(provide 'chezmoi)
;;; chezmoi.el ends here
