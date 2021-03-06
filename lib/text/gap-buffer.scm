;;;
;;; text.gap-buffer - gap-buffer for character array
;;;
;;;   Copyright (c) 2015  Shiro Kawai  <shiro@acm.org>
;;;
;;;   Redistribution and use in source and binary forms, with or without
;;;   modification, are permitted provided that the following conditions
;;;   are met:
;;;
;;;   1. Redistributions of source code must retain the above copyright
;;;      notice, this list of conditions and the following disclaimer.
;;;
;;;   2. Redistributions in binary form must reproduce the above copyright
;;;      notice, this list of conditions and the following disclaimer in the
;;;      documentation and/or other materials provided with the distribution.
;;;
;;;   3. Neither the name of the authors nor the names of its contributors
;;;      may be used to endorse or promote products derived from this
;;;      software without specific prior written permission.
;;;
;;;   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
;;;   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
;;;   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
;;;   A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
;;;   OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
;;;   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
;;;   TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
;;;   PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
;;;   LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
;;;   NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
;;;   SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
;;;

;; A simple gap-buffer implementation for the back-end of
;; text editor/viewer.

;; For the time being, we naively use flat vector for the buf.
;; It isn't gc-friendly, especially when the buffer is large.  If
;; it becomes an issue, we'll employ more sophisticated structure.

(define-module text.gap-buffer
  (use gauche.uvector)
  (use gauche.generator)
  (export gap-buffer? gap-buffer-gap-start gap-buffer-gap-end
          gap-buffer-capacity gap-buffer-content-length
          string->gap-buffer
          gap-buffer-move!
          gap-buffer-insert!
          gap-buffer-delete!
          gap-buffer->generator
          gap-buffer->string)
  )
(select-module text.gap-buffer)

(define-class <gap-buffer> ()
  ([buffer :init-keyword :buffer]
   [gap-start :init-keyword :gap-start]
   [gap-end :init-keyword :gap-end]))

(define-inline (%gbuf-size gbuf) (u32vector-length (~ gbuf'buffer)))
(define-inline (%gbuf-content-length gbuf)
  (- (%gbuf-size gbuf)
     (- (~ gbuf'gap-end) (~ gbuf'gap-start))))

;; API
(define (gap-buffer? obj) (is-a? obj <gap-buffer>))

;; API
(define (gap-buffer-gap-start gbuf)
  (check-arg gap-buffer? gbuf)
  (~ gbuf'gap-start))

;; API
(define (gap-buffer-gap-end gbuf)
  (check-arg gap-buffer? gbuf)
  (~ gbuf'gap-end))

;; API
(define (gap-buffer-capacity gbuf)
  (check-arg gap-buffer? gbuf)
  (%gbuf-size gbuf))

;; API
(define (gap-buffer-content-length gbuf)
  (check-arg gap-buffer? gbuf)
  (%gbuf-content-length gbuf))

;; Returns gap-start and gap-end index
(define (%calculate-gap-position source-len buffer-len pos whence)
  (let1 gap-start (case whence
                    [(begin) pos]
                    [(end) (- source-len pos)]
                    [else
                     (error "either a symbol `begin' or `end' required \
                             but got:" whence)])
    (unless (<= 0 gap-start source-len)
      (errorf "position ~a from ~a is out of bound of the source"
              pos whence))
    (values gap-start (- buffer-len (- source-len gap-start)))))

;; API
(define (string->gap-buffer string
                            :optional (pos 0) (whence 'end)
                                      (start 0) (end (undefined)))
  (let* ([slen (string-length string)]
         [source (if (undefined? end)
                   (if (= start 0)
                     string
                     (string-copy string start))
                   (string-copy string start end))]
         [bufsiz (expt 2 (integer-length (string-length source)))]
         [buf (make-u32vector bufsiz 0)])
    (receive (gap-start gap-end) (%calculate-gap-position (string-length source)
                                                          bufsiz pos whence)
      (string->u32vector! buf 0 source 0 gap-start)
      (string->u32vector! buf gap-end source gap-start)
      (make <gap-buffer>
        :buffer buf :gap-start gap-start :gap-end gap-end))))

;; API
(define (gap-buffer-move! gbuf pos :optional (whence 'start))
  (let ([abspos (case whence
                  [(start) pos]
                  [(current) (+ pos (~ gbuf 'gap-start))]
                  [(end) (+ pos (%gbuf-content-length gbuf))]
                  [else (errorf "position ~a from ~a is out of buffer"
                                pos whence)])]
        [start (~ gbuf 'gap-start)]
        [end   (~ gbuf 'gap-end)]
        [buf   (~ gbuf 'buffer)])
    (cond [(< abspos start)
           (let1 newend (- end (- start abspos))
             (u32vector-copy! buf newend buf abspos start)
             (set! (~ gbuf 'gap-start) abspos)
             (set! (~ gbuf 'gap-end) newend))]
          [(> abspos start)
           (let1 newend (+ end (- abspos start))
             (u32vector-copy! buf start buf end newend)
             (set! (~ gbuf 'gap-start) abspos)
             (set! (~ gbuf 'gap-end) newend))])
    gbuf))

;; API
;; content can be a string or a char
(define (gap-buffer-insert! gbuf content)
  (let ([clen (cond [(string? content) (string-length content)]
                    [(char? content) 1]
                    [else (error "string or char required, but got:" content)])]
        [start (~ gbuf'gap-start)]
        [end   (~ gbuf'gap-end)])
    (if (< (- end start) clen)
      (gap-buffer-insert! (%gap-buffer-extend! gbuf) content)
      (cond [(string? content)
             (string->u32vector! (~ gbuf'buffer) start content)
             (set! (~ gbuf'gap-start) (+ start clen))]
            [else
             (u32vector-set! (~ gbuf'buffer) start (char->integer content))
             (set! (~ gbuf'gap-start) (+ start 1))])))
  gbuf)

(define (%gap-buffer-extend! gbuf)
  (let* ([oldbuf (~ gbuf'buffer)]
         [oldlen (u32vector-length oldbuf)]
         [newlen (* 2 oldlen)]
         [newbuf (make-u32vector newlen 0)]
         [newend (+ (~ gbuf'gap-end) oldlen)])
    (u32vector-copy! newbuf 0 oldbuf 0 (~ gbuf'gap-start))
    (u32vector-copy! newbuf newend oldbuf (~ gbuf'gap-end))
    (set! (~ gbuf'buffer) newbuf)
    (set! (~ gbuf'gap-end) newend)
    gbuf))

;; API
(define (gap-buffer-delete! gbuf size)
  (let1 newend (+ (~ gbuf'gap-end) size)
    (when (< (%gbuf-size gbuf) newend)
      (error "deletion size too big:" size))
    (set! (~ gbuf'gap-end) newend)
    gbuf))

;; API
;; NB: For better performance, we don't consider the case when gbuf is
;; modified during traversal.
(define (gap-buffer->generator gbuf :optional (start 0) (end (undefined)))
  (let ([count (- (min (%gbuf-content-length gbuf)
                       (if (undefined? end) +inf.0 end))
                  start)]
        [gap-start (~ gbuf'gap-start)]
        [gap-skip  (- (~ gbuf'gap-end) (~ gbuf'gap-start))]
        [index start])
    (when (< count 0)
      (error "start index is too large:" start))
    (^[]
      (cond [(zero? count) (eof-object)]
            [(< index gap-start)
             (begin0 (integer->char (u32vector-ref (~ gbuf'buffer) index))
               (dec! count)
               (inc! index))]
            [else
             (let1 xindex (+ index gap-skip)
               (if (< xindex (%gbuf-size gbuf))
                 (begin0 (integer->char (u32vector-ref (~ gbuf'buffer) xindex))
                   (dec! count)
                   (inc! index))
                 (begin (set! count 0) (eof-object))))]))))

;; API
(define (gap-buffer->string gbuf :optional (start 0) (end (undefined)))
  (let1 g (gap-buffer->generator gbuf start end)
    (with-output-to-string (^[] (generator-for-each display g)))))
