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
