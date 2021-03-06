;;; chezmoi.el --- chezmoi management

;;; Copyright (C) 2020 Chris Overcash

;;; Author: Chris Overcash <covercash2@gmail.com>
;;; Version: 0.1.0

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;; In this file "source" is used to describe files
;;; that exist in the chezmoi repo.
;;; By contrast, "destination" describes the
;;; location where the file should be placed after editing,
;;; e.g. source: $(chezmoi source-path)/dot_profile
;;; destination: ~/.profile
;;; Some simple commands for working with chezmoi.
;;; Code:

(defconst chezmoi-output-buffer-name "*chezmoi output*")
(defconst chezmoi-diff-buffer-name "*chezmoi diff*")

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

(defun chezmoi-diff (&optional targets)
  "Prints the difference between the target state and the destination\
state for TARGETS."
  (interactive)
  (set-process-sentinel
   (start-process "chezmoi diff"
		  (chezmoi--diff-get-buffer-create)
		  "chezmoi" "diff" "--no-pager")
   'chezmoi--diff-sentinel)
  )

(defun chezmoi-apply ()
  "Apply chezmoi config."
  (interactive)
  ; set process callback
  (set-process-sentinel
   (start-process "chezmoi apply"
		  chezmoi-output-buffer-name
		  "chezmoi" "apply" "--verbose")
   'chezmoi-apply-sentinel))

(defun chezmoi-apply-dry-run ()
  "Show configuration changes in the chezmoi output buffer."
  (interactive)
  (set-process-sentinel
   (start-process "chezmoi apply dry run"
		  chezmoi-output-buffer-name
		  "chezmoi" "apply" "--dry-run" "--verbose")
   'chezmoi-apply-sentinel))

(defun chezmoi--apply-sentinel (process event)
  "Sentinel for chezmoi apply PROCESS to handle EVENTs."
  (cond
   ((string= event "finished\n")
    (message "chezmoi apply finished. check %s for more info"
	     chezmoi-output-buffer-name))
   (t nil)))

(defun chezmoi--diff-sentinel (process event)
  "Sentinel for opening the diff buffer when PROCESS receives a finished EVENT."
  (cond
   ((string= event "finished\n")
    (switch-to-buffer (chezmoi--diff-get-buffer-create)))
   (t nil)))

(defun chezmoi--diff-get-buffer-create ()
  "Get configured diff buffer.
The name is meant to reflect the behavior of =get-buffer-create=.
If the buffer has not been created, sets major mode, etc."
  (let ((init (get-buffer chezmoi-diff-buffer-name))
	(buffer (get-buffer-create chezmoi-diff-buffer-name)))
    (cond (init
	   (with-current-buffer
	       (get-buffer-create chezmoi-diff-buffer-name)
	     (diff-mode)
	     ; return diff buffer
	     (current-buffer)))
	  (t buffer)))
  )

(provide 'chezmoi)
;;; chezmoi.el ends here
