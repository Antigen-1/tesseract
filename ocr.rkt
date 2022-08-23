;;Copyright 2022 ZhangHao
;;本程序是自由软件：你可以再分发之和/或依照由自由软件基金会发布的 GNU 通用公共许可证修改之，无论是版本 3 许可证，还是（按你的决定）任何以后版都可以。
;;发布该程序是希望它能有用，但是并无保障;甚至连可销售和符合某个特定的目的都不保证。请参看 GNU 通用公共许可证，了解详情。
;;你应该随程序获得一份 GNU 通用公共许可证的复本。如果没有，请看 <https://www.gnu.org/licenses/>。
#lang racket/base
(require ffi/unsafe ffi/unsafe/define racket/runtime-path)
(provide (all-defined-out))

(define-runtime-path libdir "./shared/lib")

(define tesseract (ffi-lib "libtesseract" #f #:get-lib-dirs (lambda () (list libdir))))
(define-ffi-definer define-tesseract tesseract)

(define TessResultRenderer_p (_cpointer/null 'TessResultRenderer))
(define TessBaseAPI_p (_cpointer 'TessBaseAPI))

(define-tesseract TessVersion (_fun -> _string))
(define-tesseract TessBaseAPICreate (_fun -> TessBaseAPI_p))
(define-tesseract TessBaseAPIDelete (_fun TessBaseAPI_p -> _void))
(define-tesseract TessBaseAPIInit3
  (_fun (a : TessBaseAPI_p) _path _string -> (r : _int)
        -> (if (zero? r) (void) (begin (TessBaseAPIDelete a) (error "TessBaseAPIInit3 : fail.")))))
(define-tesseract TessBaseAPIProcessPages
  (_fun (a : TessBaseAPI_p) _path _bytes _int TessResultRenderer_p -> (r : _int)
        -> (if (not (zero? r)) r (begin (TessBaseAPIDelete a) (error "TessBaseAPIProcessPages : fail.")))))
(define-tesseract TessBaseAPIGetUTF8Text (_fun TessBaseAPI_p -> _string))

(define process
  (lambda (tessdata-prefix lang filename)
    (define api (TessBaseAPICreate))
    (TessBaseAPIInit3 api tessdata-prefix lang)
    (TessBaseAPIProcessPages api (path->complete-path filename) #f 0 #f)
    (define bytes (TessBaseAPIGetUTF8Text api))
    (TessBaseAPIDelete api)
    bytes))