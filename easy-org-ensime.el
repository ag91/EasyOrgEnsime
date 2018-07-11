;;; easy-org-ensime.el --- Easy Scala literate programming with Org Mode and Ensime.

;; Copyright (C) 2018 Andrea Giugliano

;; Author: Andrea Giugliano <agiugliano@live.it>
;; Version: 0.0.0
;; Package-Version: 20180607.000
;; Keywords: ensime org-mode

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

;; Easy Scala literate programming with Org Mode and Ensime.
;;
;; You need async.el, sbt, sbt-ensime plugin, and ensime for this mode
;; to run smoothly.
;;
;; See documentation on https://github.com/ag91/easy-org-ensime.el

;;; Code:
(require 'async)
(require 'ensime)

(defgroup eoe nil
  "Options specific to Easy Org Ensime."
  :tag "Easy Org Ensime"
  :group 'eoe)

(defcustom eoe-default-build-sbt
  "lazy val root = (project in file(\".\")).\n  settings(\n    inThisBuild(List(\n      scalaVersion := \"2.12.6\",\n      version := \"0.1.0-SNAPSHOT\")),\n    name := \"test\"\n)"
  "Default build.sbt used to load Ensime"
  :group 'eoe
  :type 'string
  )

(defcustom eoe-dir
  "/tmp/"
  "Ensime working directory"
  :group 'eoe
  :type 'string
  )

;; this cleans the output until it is fixed in ob-scala
(defun org-babel-execute:scala (body params)
  "Execute a block of Scalacode with org-babel.
This function is called by `org-babel-execute-src-block'"
  (message "executing Scala source code block")
  (let* ((processed-params (org-babel-process-params params))
         ;; set the session
         (session (org-babel-scala-initiate-session (assoc-default :session processed-params)))
         ;; variables assigned for use in the block
         (vars (assoc-default :vars processed-params))
         (result-params (assoc-default :result-params processed-params))
         ;; either OUTPUT or VALUE which should behave as described above
         (result-type (assoc-default :result-type processed-params))
         ;; expand the body with `org-babel-expand-body:scala'
         (full-body (org-babel-expand-body:scala
                     body params processed-params)))
    (ensime-inf-assert-running)
    (let ((temp-file (make-temp-file "scala-eval")))
       ;(message temp-file)
       (with-temp-file temp-file
         (insert full-body))
       ;; load the result
       (org-babel-comint-with-output (ensime-inf-buffer-name "ob_scala_eol")
         (ensime-inf-send-string (concat ":load " temp-file))
         (comint-send-input nil t)
         (sleep-for 0 5))
       (delete-file temp-file))
     ; get the result from the REPL buffer
    (org-babel-scala-table-or-string
     (with-current-buffer ensime-inf-buffer-name
       (save-excursion
         (goto-char (point-max))
         (forward-line -2)
         (end-of-line)
         (let ((end (point)))
           (if (search-backward "Loading " nil t)
               (progn
                 (forward-line 1)
                 (beginning-of-line)
                 (split-string (buffer-substring-no-properties (point) (search-forward "ob_scala_eol" nil t)) "ob_scala_eol"))
             nil)))))))

(defun org-babel-scala-table-or-string (results)
  "If the results look like a table, then convert them into an
Emacs-lisp table, otherwise return the results as a string."
  ;;FIXME enable the table results?
  (message (format "%S" results))
  (org-babel-script-escape
   (org-trim
    (mapconcat
     (lambda (element) element)
     results
     ""))))


;;;###autoload
(defun eoe-run ()
  "Create a sample scala project, and start ensime server"
  (interactive)
  (let ((build-sbt (concat eoe-dir "build.sbt")))
    (if (not (file-exists-p build-sbt))
        (with-temp-file build-sbt
          (insert eoe-default-build-sbt)))  
    (async-start
     `(lambda ()
        (shell-command (concat "cd " ,eoe-dir ";sbt ensimeConfig")))

     `(lambda (result)
        (with-temp-buffer
          (advice-add  'ensime-handle-compiler-ready :after #'ensime-inf-run-scala)
          (cd ,eoe-dir)
          (ensime)
          (message "Scala setup ready: can start your ob-scala hacking as soon as Ensime gives the okay."))))))

(provide 'eoe)
;;; easy-org-ensime.el ends here

;; Local Variables:
;; time-stamp-pattern: "10/Version:\\\\?[ \t]+1.%02y%02m%02d\\\\?\n"
;; End:
