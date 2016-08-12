#lang br
(require racket/struct (for-syntax br/datum))
(provide define-datatype cases occurs-free?)

#;(begin
    (struct lc-exp () #:transparent)
    
    (struct var-exp lc-exp (var) #:transparent
      #:guard (λ(var name)
                (unless (symbol? var)
                  (error name (format "arg ~a not ~a" var 'symbol?)))
                (values var)))
    
    (struct lambda-exp lc-exp (bound-var body) #:transparent
      #:guard (λ(bound-var body name)
                (unless (symbol? bound-var)
                  (error name (format "arg ~a not ~a" bound-var 'symbol?)))
                (unless (lc-exp? body)
                  (error name (format "arg ~a not ~a" body 'lc-exp?)))
                (values bound-var body)))
    
    (struct app-exp lc-exp (rator rand) #:transparent
      #:guard (λ(rator rand name)
                (unless (lc-exp? rator)
                  (error name (format "arg ~a not ~a" rator 'lc-exp?)))
                (unless (lc-exp? rand)
                  (error name (format "arg ~a not ~a" rand 'lc-exp?)))
                (values rator rand))))


(define #'(define-datatype _base-type _base-type-predicate?
            (_subtype [_field _field-predicate?] ...) ...)
  #'(begin
      (struct _base-type () #:transparent #:mutable)
      (struct _subtype _base-type (_field ...) #:transparent #:mutable
        #:guard (λ(_field ... name)
                  (unless (_field-predicate? _field)
                    (error name (format "arg ~a is not ~a" _field '_field-predicate?))) ...
                  (values _field ...))) ...))


(define-datatype lc-exp lc-exp?
  (var-exp [var symbol?])
  (lambda-exp [bound-var symbol?] [body lc-exp?])
  (app-exp [rator lc-exp?] [rand lc-exp?]))


#;(define (occurs-free? search-var exp)
    (cond
      [(var-exp? exp) (let ([var (var-exp-var exp)])
                        (eqv? var  search-var))]
      [(lambda-exp? exp) (let ([bound-var (lambda-exp-bound-var exp)]
                               [body (lambda-exp-body exp)])
                           (and (not (eqv? search-var bound-var))
                                (occurs-free? search-var body)))]
      [(app-exp? exp) (let ([rator (app-exp-rator exp)]
                            [rand (app-exp-rand exp)])
                        (or
                         (occurs-free? search-var rator)
                         (occurs-free? search-var rand)))]))

(define-syntax (cases stx)
  (syntax-case stx (else)
    [(_ _base-type _input-var
        [_subtype (_positional-var ...) . _body] ...
        [else . _else-body])
     (inject-syntax ([#'(_subtype? ...) (suffix-id #'(_subtype ...) "?")])
                    #'(cond
                        [(_subtype? _input-var) (match-let ([(list _positional-var ...) (struct->list _input-var)])
                                                    . _body)] ...
                                                                 [else . _else-body]))]
    [(_ _base-type _input-var
        _subtype-case ...)
     #'(cases _base-type _input-var
         _subtype-case ...
         [else (void)])]))


(define (occurs-free? search-var exp)
  (cases lc-exp exp
    [var-exp (var) (eqv? var search-var)]
    [lambda-exp (bound-var body)
                (and (not (eqv? search-var bound-var))
                     (occurs-free? search-var body))]
    [app-exp (rator rand)
             (or
              (occurs-free? search-var rator)
              (occurs-free? search-var rand))]))


(module+ test
  (require rackunit)
  (check-true (occurs-free? 'foo (var-exp 'foo)))
  (check-false (occurs-free? 'foo (var-exp 'bar)))
  (check-false (occurs-free? 'foo (lambda-exp 'foo (var-exp 'bar))))
  (check-true (occurs-free? 'foo (lambda-exp 'bar (var-exp 'foo))))
  (check-true (occurs-free? 'foo (lambda-exp 'bar (lambda-exp 'zim (lambda-exp 'zam (var-exp 'foo)))))))