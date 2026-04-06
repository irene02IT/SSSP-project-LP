;;; -*- Mode: Lisp -*-

;;; test_sssp.lisp
;;;
;;; Test suite per sssp.lisp
;;; Caricare con: (load "sssp.lisp") poi (load "test_sssp.lisp")
;;; Eseguire tutti i test con: (run-all-tests)


;;; -----------------------------------------------------------------------
;;; Utilità di test
;;; -----------------------------------------------------------------------

(defparameter *pass-count* 0)
(defparameter *fail-count* 0)

;;; assert-true/2
;;; Verifica che value sia non-NIL.
(defun assert-true (name value)
  (if value
      (progn (incf *pass-count*)
             (format t "PASS: ~a~%" name))
    (progn (incf *fail-count*)
           (format t "FAIL: ~a  (atteso non-NIL, ottenuto NIL)~%" name))))

;;; assert-false/2
;;; Verifica che value sia NIL.
(defun assert-false (name value)
  (if (not value)
      (progn (incf *pass-count*)
             (format t "PASS: ~a~%" name))
    (progn (incf *fail-count*)
           (format t "FAIL: ~a  (atteso NIL, ottenuto ~a)~%" name value))))

;;; assert-equal/3
;;; Verifica che actual sia EQUAL a expected.
(defun assert-equal (name expected actual)
  (if (equal expected actual)
      (progn (incf *pass-count*)
             (format t "PASS: ~a~%" name))
    (progn (incf *fail-count*)
           (format t "FAIL: ~a  (atteso ~a, ottenuto ~a)~%" name expected actual))))

;;; assert-eql-number/3
;;; Verifica che actual sia numericamente uguale a expected (con = per float).
(defun assert-eql-number (name expected actual)
  (if (and (numberp actual) (= expected actual))
      (progn (incf *pass-count*)
             (format t "PASS: ~a~%" name))
    (progn (incf *fail-count*)
           (format t "FAIL: ~a  (atteso ~a, ottenuto ~a)~%" name expected actual))))

;;; clean-all/0
;;; Azzera tutti i dati globali tra un test e l'altro.
(defun clean-all ()
  (clrhash *graphs*)
  (clrhash *vertices*)
  (clrhash *arcs*)
  (clrhash *visited*)
  (clrhash *distances*)
  (clrhash *previous*)
  (clrhash *heaps*))

;;; setup-project-graph/0
;;; Ricrea il grafo del progetto (6 vertici, 10 archi, sorgente r).
(defun setup-project-graph ()
  (clean-all)
  (test 'proj))

;;; section/1
;;; Stampa un'intestazione di sezione.
(defun section (title)
  (format t "~%=== ~a ===~%" title))


;;; -----------------------------------------------------------------------
;;; Test: MinHeap
;;; -----------------------------------------------------------------------

(defun test-heap-new ()
  (clean-all)
  (new-heap 'h1)
  (assert-true  "heap creato in *heaps*"  (is-heap 'h1))
  (assert-true  "heap vuoto"              (heap-empty 'h1))
  (assert-false "heap non pieno"          (heap-not-empty 'h1))
  (clean-all))

(defun test-heap-insert-single ()
  (clean-all)
  (new-heap 'h1)
  (heap-insert 'h1 5 'a)
  (assert-equal "size dopo insert"  '(5 a)  (heap-head 'h1))
  (assert-true  "not-empty"                  (heap-not-empty 'h1))
  (clean-all))

(defun test-heap-insert-order ()
  (clean-all)
  (new-heap 'h1)
  (heap-insert 'h1 10 'c)
  (heap-insert 'h1  3 'a)
  (heap-insert 'h1  7 'b)
  ;;; La radice deve essere l'elemento con chiave minima.
  (assert-equal "head e' il minimo"  '(3 a)  (heap-head 'h1))
  (clean-all))

(defun test-heap-extract ()
  (clean-all)
  (new-heap 'h1)
  (heap-insert 'h1 10 'c)
  (heap-insert 'h1  3 'a)
  (heap-insert 'h1  7 'b)
  (let ((e1 (heap-extract 'h1))
        (e2 (heap-extract 'h1))
        (e3 (heap-extract 'h1)))
    (assert-equal "primo estratto"   '(3 a)  e1)
    (assert-equal "secondo estratto" '(7 b)  e2)
    (assert-equal "terzo estratto"   '(10 c) e3)
    (assert-true  "heap vuoto dopo extract" (heap-empty 'h1)))
  (clean-all))

(defun test-heap-extract-empty ()
  (clean-all)
  (new-heap 'h1)
  ;;; Estrarre da heap vuoto deve restituire NIL, non segnalare errore.
  (assert-false "extract da heap vuoto = NIL" (heap-extract 'h1))
  (clean-all))

(defun test-heap-modify-key ()
  (clean-all)
  (new-heap 'h1)
  (heap-insert 'h1 10 'a)
  (heap-insert 'h1 20 'b)
  (heap-insert 'h1 30 'c)
  ;;; Abbassa la chiave di c da 30 a 5: deve diventare la nuova radice.
  (heap-modify-key 'h1 5 30 'c)
  (assert-equal "dopo modify_key testa e' c" '(5 c) (heap-head 'h1))
  (clean-all))

(defun test-heap-expand ()
  ;;; Forza l'espansione dell'array inserendo più elementi della capacity iniziale.
  (clean-all)
  (new-heap 'h1 3)   ;;; Capacity iniziale = 3.
  (heap-insert 'h1 4 'd)
  (heap-insert 'h1 2 'b)
  (heap-insert 'h1 3 'c)
  (heap-insert 'h1 1 'a)   ;;; Qui deve scattare l'expand.
  (assert-equal "testa dopo expand" '(1 a) (heap-head 'h1))
  (let ((size (heap-size (gethash 'h1 *heaps*))))
    (assert-equal "size = 4 dopo expand" 4 size))
  (clean-all))

(defun test-heap-many-inserts-extract-order ()
  ;;; Stress: inserisce 5 elementi disordinati, li estrae e verifica l'ordine.
  (clean-all)
  (new-heap 'hh)
  (heap-insert 'hh 50 'e50)
  (heap-insert 'hh 10 'e10)
  (heap-insert 'hh 30 'e30)
  (heap-insert 'hh 20 'e20)
  (heap-insert 'hh 40 'e40)
  (let ((k1 (first (heap-extract 'hh)))
        (k2 (first (heap-extract 'hh)))
        (k3 (first (heap-extract 'hh)))
        (k4 (first (heap-extract 'hh)))
        (k5 (first (heap-extract 'hh))))
    (assert-equal "extract ordine 1" 10 k1)
    (assert-equal "extract ordine 2" 20 k2)
    (assert-equal "extract ordine 3" 30 k3)
    (assert-equal "extract ordine 4" 40 k4)
    (assert-equal "extract ordine 5" 50 k5))
  (clean-all))

(defun test-heap-delete ()
  (clean-all)
  (new-heap 'h1)
  (heap-insert 'h1 1 'a)
  (heap-delete 'h1)
  (assert-false "heap eliminato da *heaps*" (is-heap 'h1))
  (clean-all))


;;; -----------------------------------------------------------------------
;;; Test: API Grafi
;;; -----------------------------------------------------------------------

(defun test-new-graph ()
  (clean-all)
  (new-graph 'g)
  (assert-true  "grafo esiste"       (is-graph 'g))
  (new-graph 'g)   ;;; Chiamata idempotente.
  (assert-equal "un solo grafo 'g'"  'g  (is-graph 'g))
  (clean-all))

(defun test-delete-graph ()
  (clean-all)
  (new-graph 'g)
  (new-vertex 'g 'a)
  (new-vertex 'g 'b)
  (new-arc 'g 'a 'b 3)
  (delete-graph 'g)
  (assert-false "grafo eliminato"   (is-graph 'g))
  (assert-false "vertice eliminato" (is-vertex 'g 'a))
  (assert-false "arco eliminato"    (is-arc 'g 'a 'b))
  (clean-all))

(defun test-new-vertex ()
  (clean-all)
  (new-graph 'g)
  (new-vertex 'g 'v1)
  (assert-true "vertice esiste" (is-vertex 'g 'v1))
  (clean-all))

(defun test-new-arc-basic ()
  (clean-all)
  (new-graph 'g)
  (new-vertex 'g 'u)
  (new-vertex 'g 'v)
  (new-arc 'g 'u 'v 4)
  (assert-equal "arco con peso 4"
                '(arc g u v 4)
                (is-arc 'g 'u 'v))
  (clean-all))

(defun test-new-arc-default-weight ()
  (clean-all)
  (new-graph 'g)
  (new-vertex 'g 'u)
  (new-vertex 'g 'v)
  (new-arc 'g 'u 'v)
  (assert-equal "peso default 1"
                '(arc g u v 1)
                (is-arc 'g 'u 'v))
  (clean-all))

(defun test-new-arc-replace ()
  ;;; Se l'arco esiste con peso diverso deve essere sostituito.
  (clean-all)
  (new-graph 'g)
  (new-vertex 'g 'u)
  (new-vertex 'g 'v)
  (new-arc 'g 'u 'v 4)
  (new-arc 'g 'u 'v 9)
  (assert-equal "arco aggiornato a 9"
                '(arc g u v 9)
                (is-arc 'g 'u 'v))
  (clean-all))

(defun test-graph-vertices ()
  (clean-all)
  (new-graph 'g)
  (new-vertex 'g 'a)
  (new-vertex 'g 'b)
  (new-vertex 'g 'c)
  (let ((vs (graph-vertices 'g)))
    (assert-equal "3 vertici" 3 (length vs)))
  (clean-all))

(defun test-graph-arcs ()
  (clean-all)
  (new-graph 'g)
  (new-vertex 'g 'a)
  (new-vertex 'g 'b)
  (new-arc 'g 'a 'b 1)
  (new-arc 'g 'b 'a 2)
  (let ((es (graph-arcs 'g)))
    (assert-equal "2 archi" 2 (length es)))
  (clean-all))

(defun test-graph-vertex-neighbors ()
  (clean-all)
  (new-graph 'g)
  (new-vertex 'g 'a)
  (new-vertex 'g 'b)
  (new-vertex 'g 'c)
  (new-arc 'g 'a 'b 1)
  (new-arc 'g 'a 'c 2)
  (assert-equal "2 vicini di a" 2 (length (graph-vertex-neighbors 'g 'a)))
  (assert-equal "0 vicini di b" 0 (length (graph-vertex-neighbors 'g 'b)))
  (clean-all))


;;; -----------------------------------------------------------------------
;;; Test: Dijkstra — grafo base del progetto
;;; -----------------------------------------------------------------------
;;;
;;; Grafo: r->s(5), r->t(3), s->t(2), s->x(3), t->x(7), t->y(4),
;;;        t->z(8), x->y(1), x->z(2), y->x(10)
;;; Sorgente: r
;;; Distanze attese: r=0, s=5, t=3, x=8, y=9, z=10

(defun test-dijkstra-distances ()
  (setup-project-graph)
  (sssp-dijkstra 'proj 'r)
  (assert-eql-number "dist r=0"  0  (sssp-dist 'proj 'r))
  (assert-eql-number "dist s=5"  5  (sssp-dist 'proj 's))
  (assert-eql-number "dist t=3"  3  (sssp-dist 'proj 't))
  (assert-eql-number "dist x=8"  8  (sssp-dist 'proj 'x))
  (assert-eql-number "dist y=7"  7  (sssp-dist 'proj 'y))
  (assert-eql-number "dist z=10" 10 (sssp-dist 'proj 'z))
  (clean-all))

(defun test-dijkstra-visited ()
  (setup-project-graph)
  (sssp-dijkstra 'proj 'r)
  (assert-true "r visitato" (sssp-visited 'proj 'r))
  (assert-true "s visitato" (sssp-visited 'proj 's))
  (assert-true "t visitato" (sssp-visited 'proj 't))
  (assert-true "x visitato" (sssp-visited 'proj 'x))
  (assert-true "y visitato" (sssp-visited 'proj 'y))
  (assert-true "z visitato" (sssp-visited 'proj 'z))
  (clean-all))

(defun test-shortest-path-r-to-z ()
  ;;; Cammino ottimo r->t(3)->x(8)->z(10): 3 archi.
  (setup-project-graph)
  (sssp-dijkstra 'proj 'r)
  (let ((path (sssp-shortest-path 'proj 'r 'z)))
    (assert-equal "path r->z ha 3 archi" 3 (length path))
    (assert-equal "primo arco r->t" 'r (third (first path)))
    (assert-equal "ultimo nodo z"   'z (fourth (third path))))
  (clean-all))

(defun test-shortest-path-r-to-y ()
  ;;; Cammino ottimo r->t->y = 3+4=7: 2 archi.
  ;;; (r->s->x->y = 5+3+1=9 > 7)
  (setup-project-graph)
  (sssp-dijkstra 'proj 'r)
  (let ((path (sssp-shortest-path 'proj 'r 'y)))
    (assert-equal "path r->y ha 2 archi" 2 (length path)))
  (clean-all))

(defun test-shortest-path-source-to-source ()
  ;;; Il cammino da sorgente a se stessa deve essere la lista vuota.
  (setup-project-graph)
  (sssp-dijkstra 'proj 'r)
  (let ((path (sssp-shortest-path 'proj 'r 'r)))
    (assert-equal "path r->r e' vuota" '() path))
  (clean-all))

(defun test-dijkstra-idempotent ()
  ;;; Due esecuzioni consecutive devono dare gli stessi risultati.
  (setup-project-graph)
  (sssp-dijkstra 'proj 'r)
  (sssp-dijkstra 'proj 'r)
  (assert-eql-number "dist r=0 dopo doppia esecuzione"  0  (sssp-dist 'proj 'r))
  (assert-eql-number "dist z=10 dopo doppia esecuzione" 10 (sssp-dist 'proj 'z))
  (clean-all))


;;; -----------------------------------------------------------------------
;;; Test: Edge Cases
;;; -----------------------------------------------------------------------

(defun test-single-vertex ()
  ;;; Grafo con un solo vertice: distanza da sé stesso = 0.
  (clean-all)
  (new-graph 'g)
  (new-vertex 'g 'a)
  (sssp-dijkstra 'g 'a)
  (assert-eql-number "dist a=0" 0 (sssp-dist 'g 'a))
  (let ((path (sssp-shortest-path 'g 'a 'a)))
    (assert-equal "path a->a vuoto" '() path))
  (clean-all))

(defun test-disconnected-graph ()
  ;;; b non raggiungibile da a: la sua distanza deve rimanere +inf.
  (clean-all)
  (new-graph 'g)
  (new-vertex 'g 'a)
  (new-vertex 'g 'b)
  (sssp-dijkstra 'g 'a)
  (assert-eql-number "dist a=0"   0                         (sssp-dist 'g 'a))
  (assert-equal      "dist b=inf" most-positive-double-float (sssp-dist 'g 'b))
  (clean-all))

(defun test-disconnected-path-returns-nil ()
  ;;; Il cammino verso un nodo non raggiungibile deve restituire NIL.
  (clean-all)
  (new-graph 'g)
  (new-vertex 'g 'a)
  (new-vertex 'g 'b)
  (sssp-dijkstra 'g 'a)
  (let ((path (sssp-shortest-path 'g 'a 'b)))
    (assert-false "path verso nodo irraggiungibile = NIL" path))
  (clean-all))

(defun test-two-graphs-independent ()
  ;;; Due esecuzioni su grafi diversi devono essere indipendenti.
  (clean-all)
  (new-graph 'g1)
  (new-vertex 'g1 'a) (new-vertex 'g1 'b)
  (new-arc 'g1 'a 'b 3)
  (new-graph 'g2)
  (new-vertex 'g2 'a) (new-vertex 'g2 'b)
  (new-arc 'g2 'a 'b 99)
  (sssp-dijkstra 'g1 'a)
  (sssp-dijkstra 'g2 'a)
  (assert-eql-number "dist g1 a->b = 3"  3  (sssp-dist 'g1 'b))
  (assert-eql-number "dist g2 a->b = 99" 99 (sssp-dist 'g2 'b))
  (clean-all))

(defun test-arc-weight-zero ()
  ;;; Archi con peso 0 sono ammessi.
  (clean-all)
  (new-graph 'g)
  (new-vertex 'g 'a) (new-vertex 'g 'b)
  (new-arc 'g 'a 'b 0)
  (sssp-dijkstra 'g 'a)
  (assert-eql-number "dist b=0 con arco peso 0" 0 (sssp-dist 'g 'b))
  (clean-all))

(defun test-arc-weight-float ()
  ;;; I pesi possono essere float (confermato dal professore).
  (clean-all)
  (new-graph 'g)
  (new-vertex 'g 'a) (new-vertex 'g 'b)
  (new-arc 'g 'a 'b 4.2)
  (sssp-dijkstra 'g 'a)
  (assert-eql-number "dist b=4.2" 4.2 (sssp-dist 'g 'b))
  (clean-all))

(defun test-multiple-paths-shortest-chosen ()
  ;;; Due cammini: a->b->c (1+1=2) e a->c (10). Deve scegliere peso 2.
  (clean-all)
  (new-graph 'g)
  (new-vertex 'g 'a) (new-vertex 'g 'b) (new-vertex 'g 'c)
  (new-arc 'g 'a 'b 1)
  (new-arc 'g 'b 'c 1)
  (new-arc 'g 'a 'c 10)
  (sssp-dijkstra 'g 'a)
  (assert-eql-number "dist c=2 (cammino ottimo)" 2 (sssp-dist 'g 'c))
  (let ((path (sssp-shortest-path 'g 'a 'c)))
    (assert-equal "path a->c ha 2 archi" 2 (length path)))
  (clean-all))

(defun test-arc-replace-affects-dijkstra ()
  ;;; Sostituire un arco con peso minore deve influenzare Dijkstra.
  (clean-all)
  (new-graph 'g)
  (new-vertex 'g 'a) (new-vertex 'g 'b)
  (new-arc 'g 'a 'b 100)
  (new-arc 'g 'a 'b 1)   ;;; Sovrascrive.
  (sssp-dijkstra 'g 'a)
  (assert-eql-number "dist b=1 dopo sostituzione arco" 1 (sssp-dist 'g 'b))
  (clean-all))

(defun test-linear-chain ()
  ;;; Catena a->b->c->d: distanze cumulative.
  (clean-all)
  (new-graph 'g)
  (new-vertex 'g 'a) (new-vertex 'g 'b)
  (new-vertex 'g 'c) (new-vertex 'g 'd)
  (new-arc 'g 'a 'b 1)
  (new-arc 'g 'b 'c 2)
  (new-arc 'g 'c 'd 3)
  (sssp-dijkstra 'g 'a)
  (assert-eql-number "dist b=1" 1 (sssp-dist 'g 'b))
  (assert-eql-number "dist c=3" 3 (sssp-dist 'g 'c))
  (assert-eql-number "dist d=6" 6 (sssp-dist 'g 'd))
  (let ((path (sssp-shortest-path 'g 'a 'd)))
    (assert-equal "path a->d ha 3 archi" 3 (length path)))
  (clean-all))


;;; -----------------------------------------------------------------------
;;; Runner
;;; -----------------------------------------------------------------------

(defun run-all-tests ()
  (setf *pass-count* 0)
  (setf *fail-count* 0)

  (section "TEST MINHEAP")
  (test-heap-new)
  (test-heap-insert-single)
  (test-heap-insert-order)
  (test-heap-extract)
  (test-heap-extract-empty)
  (test-heap-modify-key)
  (test-heap-expand)
  (test-heap-many-inserts-extract-order)
  (test-heap-delete)

  (section "TEST API GRAFI")
  (test-new-graph)
  (test-delete-graph)
  (test-new-vertex)
  (test-new-arc-basic)
  (test-new-arc-default-weight)
  (test-new-arc-replace)
  (test-graph-vertices)
  (test-graph-arcs)
  (test-graph-vertex-neighbors)

  (section "TEST DIJKSTRA (grafo progetto)")
  (test-dijkstra-distances)
  (test-dijkstra-visited)
  (test-shortest-path-r-to-z)
  (test-shortest-path-r-to-y)
  (test-shortest-path-source-to-source)
  (test-dijkstra-idempotent)

  (section "TEST EDGE CASES")
  (test-single-vertex)
  (test-disconnected-graph)
  (test-disconnected-path-returns-nil)
  (test-two-graphs-independent)
  (test-arc-weight-zero)
  (test-arc-weight-float)
  (test-multiple-paths-shortest-chosen)
  (test-arc-replace-affects-dijkstra)
  (test-linear-chain)

  (format t "~%--- Risultato: ~a PASS, ~a FAIL ---~%"
          *pass-count* *fail-count*))

;;; end of file test_sssp.lisp
