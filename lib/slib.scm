;;; "slib.scm" configuration template of *features* for Scheme -*-scheme-*-
;;; Author: Shiro Kawai
;;; based on the "Template.scm" by Aubrey Jaffer
;;;
;;; This code is in the public domain.

;; dummy module.  slib stuffs are defined in user module.
(define-module slib
  )

;;; (software-type) should be set to the generic operating system type.
;;; UNIX, VMS, MACOS, AMIGA and MS-DOS are supported.

(define (software-type) 'UNIX)

;;; (scheme-implementation-type) should return the name of the scheme
;;; implementation loading this file.

(define (scheme-implementation-type) 'gauche)

;;; (scheme-implementation-home-page) should return a (string) URL
;;; (Uniform Resource Locator) for this scheme implementation's home
;;; page; or false if there isn't one.

(define (scheme-implementation-home-page)
  "http://www.shiro.dreamhost.com/scheme/gauche")

;;; (scheme-implementation-version) should return a string describing
;;; the version the scheme implementation loading this file.

(define (scheme-implementation-version) (gauche-version))

;;; (implementation-vicinity) should be defined to be the pathname of
;;; the directory where any auxillary files to your Scheme
;;; implementation reside.

(define (implementation-vicinity) (gauche-library-directory))

;;; (library-vicinity) should be defined to be the pathname of the
;;; directory where files of Scheme library functions reside.

(define library-vicinity
  (let ((library-path
	 (or
	  ;; Use this getenv if your implementation supports it.
	  (sys-getenv "SCHEME_LIBRARY_PATH")
	  ;; Use this path if your scheme does not support GETENV
	  ;; or if SCHEME_LIBRARY_PATH is not set.
	  (case (software-type)
	    ((UNIX) "/usr/src/slib/")
	    ((VMS) "lib$scheme:")
	    ((MS-DOS) "C:\\SLIB\\")
	    (else "")))))
    (lambda () library-path)))

;;; (home-vicinity) should return the vicinity of the user's HOME
;;; directory, the directory which typically contains files which
;;; customize a computer environment for a user.

(define home-vicinity
  (let ((home-path (sys-getenv "HOME")))
    (lambda () home-path)))

;;; *FEATURES* should be set to a list of symbols describing features
;;; of this implementation.  Suggestions for features are:

(define *features*
      '(
	source				;can load scheme source files
					;(slib:load-source "filename")
;	compiled			;can load compiled files
					;(slib:load-compiled "filename")
	rev4-report			;conforms to
	rev3-report			;conforms to
;	ieee-p1178			;conforms to
;	sicp				;runs code from Structure and
					;Interpretation of Computer
					;Programs by Abelson and Sussman.
	rev4-optional-procedures	;LIST-TAIL, STRING->LIST,
					;LIST->STRING, STRING-COPY,
					;STRING-FILL!, LIST->VECTOR,
					;VECTOR->LIST, and VECTOR-FILL!
;	rev2-procedures			;SUBSTRING-MOVE-LEFT!,
					;SUBSTRING-MOVE-RIGHT!,
					;SUBSTRING-FILL!,
					;STRING-NULL?, APPEND!, 1+,
					;-1+, <?, <=?, =?, >?, >=?
	multiarg/and-			;/ and - can take more than 2 args.
	multiarg-apply			;APPLY can take more than 2 args.
;	rationalize
	delay				;has DELAY and FORCE
	with-file			;has WITH-INPUT-FROM-FILE and
					;WITH-OUTPUT-FROM-FILE
	string-port			;has CALL-WITH-INPUT-STRING and
					;CALL-WITH-OUTPUT-STRING
;	transcript			;TRANSCRIPT-ON and TRANSCRIPT-OFF
;	char-ready?
	macro				;has R4RS high level macros
	defmacro			;has Common Lisp DEFMACRO
	eval				;R5RS two-argument eval
;	record				;has user defined data structures
	values				;proposed multiple values
	dynamic-wind			;proposed dynamic-wind
	ieee-floating-point		;conforms to
	full-continuation		;can return multiple times
;	object-hash			;has OBJECT-HASH

	sort
;	queue				;queues
;	pretty-print
;	object->string
;	format
;	trace				;has macros: TRACE and UNTRACE
;	compiler			;has (COMPILER)
;	ed				;(ED) is editor
	system				;posix (system <string>)
	getenv				;posix (getenv <string>)
	program-arguments		;returns list of strings (argv)
;	Xwindows			;X support
;	curses				;screen management package
;	termcap				;terminal description package
;	terminfo			;sysV terminal description
;	current-time			;returns time in seconds since 1/1/1970
	))

;;; (OUTPUT-PORT-WIDTH <port>)
(define (output-port-width . arg) 79)

;;; (OUTPUT-PORT-HEIGHT <port>)
(define (output-port-height . arg) 24)

;;; (CURRENT-ERROR-PORT) - Gauche has it
;(define current-error-port
;  (let ((port (current-output-port)))
;    (lambda () port)))

;;; (TMPNAM) makes a temporary file name.
(define tmpnam sys-tmpnam)

;;; GETENV
(define getenv sys-getenv)

;;; (FILE-EXISTS? <string>)
(define (file-exists? f) (sys-access f F_OK))

;;; (DELETE-FILE <string>)
(define (delete-file f)  (sys-unlink f))

;;; FORCE-OUTPUT flushes any pending output on optional arg output port
;;; use this definition if your system doesn't have such a procedure.
(define force-output flush)

;; CURRENT-TIME
;(define current-time sys-time)

;; PROGRAM-ARGUMENTS
(define (program-arguments) (with-module gauche *argv*))

;;; CALL-WITH-INPUT-STRING and CALL-WITH-OUTPUT-STRING are the string
;;; port versions of CALL-WITH-*PUT-FILE.

;;; "rationalize" adjunct procedures.
;;(define (find-ratio x e)
;;  (let ((rat (rationalize x e)))
;;    (list (numerator rat) (denominator rat))))
;;(define (find-ratio-between x y)
;;  (find-ratio (/ (+ x y) 2) (/ (- x y) 2)))

;;; CHAR-CODE-LIMIT is one greater than the largest integer which can
;;; be returned by CHAR->INTEGER.
(define char-code-limit (+ *char-code-max* 1))

;;; MOST-POSITIVE-FIXNUM is used in modular.scm
(define most-positive-fixnum #x0FFFFFFF)

;;; Return argument
(define (identity x) x)

;;; SLIB:EVAL is single argument eval using the top-level (user) environment.
(define (slib:eval expr) (eval expr (interaction-environment)))

;;; If your implementation provides R4RS macros:
(define macro:eval slib:eval)
(define macro:load load)

(define-syntax defmacro
  (syntax-rules ()
    ((_ params . body) (define-macro params . body))))

;(define *defmacros*
;  (list (cons 'defmacro
;	      (lambda (name parms . body)
;		`(set! *defmacros* (cons (cons ',name (lambda ,parms ,@body))
;					 *defmacros*))))))
;(define (defmacro? m) (and (assq m *defmacros*) #t))

(define (macroexpand-1 e)
  (eval `(%macro-expand-1 ,e) (interaction-environment)))

;(define (macroexpand-1 e)
;  (if (pair? e) (let ((a (car e)))
;		  (cond ((symbol? a) (set! a (assq a *defmacros*))
;				     (if a (apply (cdr a) (cdr e)) e))
;			(else e)))
;      e))

(define (macroexpand e)
  (eval `(%macro-expand ,e) (interaction-environment)))

;(define (macroexpand e)
;  (if (pair? e) (let ((a (car e)))
;		  (cond ((symbol? a)
;			 (set! a (assq a *defmacros*))
;			 (if a (macroexpand (apply (cdr a) (cdr e))) e))
;			(else e)))
;      e))

(define gentemp gensym)

(define base:eval slib:eval)
;(define (defmacro:eval x) (base:eval (defmacro:expand* x)))
;(define (defmacro:expand* x)
;  (require 'defmacroexpand) (apply defmacro:expand* x '()))

;(define (slib:eval-load <pathname> evl)
;  (if (not (file-exists? <pathname>))
;      (set! <pathname> (string-append <pathname> (scheme-file-suffix))))
;  (call-with-input-file <pathname>
;    (lambda (port)
;      (let ((old-load-pathname *load-pathname*))
;	(set! *load-pathname* <pathname>)
;	(do ((o (read port) (read port)))
;	    ((eof-object? o))
;	  (evl o))
;	(set! *load-pathname* old-load-pathname)))))

(define defmacro:load load)

(define slib:warn
  (lambda args
    (let ((cep (current-error-port)))
      (if (provided? 'trace) (print-call-stack cep))
      (display "Warn: " cep)
      (for-each (lambda (x) (display x cep)) args))))

;;; define an error procedure for the library
(define (slib:error . args)
  (if (provided? 'trace) (print-call-stack (current-error-port)))
  (error (string-append (with-output-to-string (for-each display args)) "\n")))

;;; define these as appropriate for your system.
(define slib:tab (integer->char 9))
(define slib:form-feed (integer->char 12))

;;; Support for older versions of Scheme.  Not enough code for its own file.
;(define (last-pair l) (if (pair? (cdr l)) (last-pair (cdr l)) l))
(define t #t)
(define nil #f)

;;; Define these if your implementation's syntax can support it and if
;;; they are not already defined.

;(define (1+ n) (+ n 1))
;(define (-1+ n) (+ n -1))
;(define 1- -1+)

(define in-vicinity string-append)

;;; Define SLIB:EXIT to be the implementation procedure to exit or
;;; return if exitting not supported.
(define slib:exit exit)

;;; Here for backward compatability
(define scheme-file-suffix
  (let ((suffix (case (software-type)
		  ((NOSVE) "_scm")
		  (else ".scm"))))
    (lambda () suffix)))

;;; (SLIB:LOAD-SOURCE "foo") should load "foo.scm" or with whatever
;;; suffix all the module files in SLIB have.  See feature 'SOURCE.

(define (slib:load-source f) (load (string-append f ".scm")))

;;; (SLIB:LOAD-COMPILED "foo") should load the file that was produced
;;; by compiling "foo.scm" if this implementation can compile files.
;;; See feature 'COMPILED.

(define slib:load-compiled load)

;;; At this point SLIB:LOAD must be able to load SLIB files.

(define slib:load slib:load-source)

(slib:load (in-vicinity (library-vicinity) "require"))

;;; A trick to make require work both on Gauche files and slib files.
;;; The hint is taken from STk.

(define-macro (require feature)         ;redefine
  (if (string? feature)
      `',(%require feature)            ;gauche version
      `(require:require ,feature)))    ;slib version

(define (provide feature)
  (if (string? feature)
      (with-module gauche (provide feature)) ;gauche version
      (require:provide feature)))       ;slib version

(define (provided? feature)
  (if (string? feature)
      (with-module gauche (provided? feature)) ;gauche version
      (require:provided? feature)))     ;slib version

(provide "slib")
