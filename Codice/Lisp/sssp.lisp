;;; -*- Mode: Lisp -*-

;;; sssp.lisp

;;; Autori:
;;; Irene E.


;;; -----------------------------------------------------------------------
;;; Hash table per la rappresentazione dei grafi
;;; -----------------------------------------------------------------------

(defparameter *graphs*    (make-hash-table :test #'equal))
(defparameter *vertices*  (make-hash-table :test #'equal))
(defparameter *arcs*      (make-hash-table :test #'equal))

;;; Hash table per l'algoritmo SSSP
(defparameter *visited*   (make-hash-table :test #'equal))
(defparameter *distances* (make-hash-table :test #'equal))
(defparameter *previous*  (make-hash-table :test #'equal))

;;; Hash table per gli heap
(defparameter *heaps*     (make-hash-table :test #'equal))


;;; -----------------------------------------------------------------------
;;; Interfaccia Common Lisp per la manipolazione dei grafi
;;; -----------------------------------------------------------------------


;;; is-graph/1
;;; Restituisce graph-id se il grafo e' presente in *graphs*, NIL altrimenti.
(defun is-graph (graph-id)
  (gethash graph-id *graphs*))


;;; new-graph/1
;;; Aggiunge un nuovo grafo al sistema se non e' gia' presente.
;;; Restituisce sempre graph-id.
(defun new-graph (graph-id)
  (or (is-graph graph-id)
      (setf (gethash graph-id *graphs*) graph-id)))


;;; delete-graph/1
;;; Elimina il grafo graph-id dal sistema insieme a tutti i suoi
;;; vertici e archi. Raccoglie prima tutte le chiavi da eliminare
;;; in liste separate, poi le rimuove: modificare una hash-table
;;; mentre la si itera con maphash e' undefined behavior in Common Lisp.
;;; Restituisce T.
(defun delete-graph (graph-id)
  (remhash graph-id *graphs*)
  (let ((keys-v '())
        (keys-a '()))
    (maphash (lambda (k v)
               (declare (ignore v))
               (when (equal (second k) graph-id)
                 (push k keys-v)))
             *vertices*)
    (maphash (lambda (k v)
               (declare (ignore v))
               (when (equal (second k) graph-id)
                 (push k keys-a)))
             *arcs*)
    (mapc (lambda (k) (remhash k *vertices*)) keys-v)
    (mapc (lambda (k) (remhash k *arcs*)) keys-a))
  t)


;;; is-vertex/2
;;; Restituisce la rappresentazione del vertice vertex-id nel grafo
;;; graph-id se presente, NIL altrimenti.
(defun is-vertex (graph-id vertex-id)
  (gethash (list 'vertex graph-id vertex-id) *vertices*))


;;; new-vertex/2
;;; Aggiunge il vertice vertex-id al grafo graph-id se non e' gia'
;;; presente. Restituisce sempre la rappresentazione del vertice.
(defun new-vertex (graph-id vertex-id)
  (or (is-vertex graph-id vertex-id)
      (setf (gethash (list 'vertex graph-id vertex-id) *vertices*)
            (list 'vertex graph-id vertex-id))))


;;; graph-vertices/1
;;; Restituisce la lista di tutti i vertici del grafo graph-id
;;; nella forma (vertex graph-id vertex-id).
(defun graph-vertices (graph-id)
  (let ((result '()))
    (maphash (lambda (k v)
               (when (equal (second k) graph-id)
                 (push v result)))
             *vertices*)
    result))


;;; is-arc/3
;;; Restituisce la rappresentazione dell'arco da vertex-1-id a vertex-2-id
;;; nel grafo graph-id se presente, NIL altrimenti.
(defun is-arc (graph-id vertex-1-id vertex-2-id)
  (gethash (list 'arc graph-id vertex-1-id vertex-2-id) *arcs*))


;;; new-arc/3 e new-arc/4
;;; Aggiunge un arco al grafo graph-id con peso weight (default 1).
;;; Se l'arco esiste gia', lo sostituisce con il nuovo peso.
;;; Restituisce la rappresentazione (arc graph-id u v weight).
(defun new-arc (graph-id vertex-1-id vertex-2-id &optional (weight 1))
  (setf (gethash (list 'arc graph-id vertex-1-id vertex-2-id) *arcs*)
        (list 'arc graph-id vertex-1-id vertex-2-id weight)))


;;; graph-arcs/1
;;; Restituisce la lista di tutti gli archi del grafo graph-id
;;; nella forma (arc graph-id u v weight).
(defun graph-arcs (graph-id)
  (let ((result '()))
    (maphash (lambda (k v)
               (when (equal (second k) graph-id)
                 (push v result)))
             *arcs*)
    result))


;;; graph-vertex-neighbors/2
;;; Restituisce la lista degli archi uscenti dal vertice vertex-id
;;; nel grafo graph-id, nella forma (arc graph-id vertex-id n weight).
(defun graph-vertex-neighbors (graph-id vertex-id)
  (let ((neighbors '()))
    (maphash (lambda (k v)
               (when (and (equal (second k) graph-id)
                          (equal (third k) vertex-id))
                 (push v neighbors)))
             *arcs*)
    neighbors))


;;; graph-print/1
;;; Stampa tutti i vertici e gli archi del grafo graph-id.
(defun graph-print (graph-id)
  (maphash (lambda (k v)
             (when (equal (second k) graph-id)
               (print v)))
           *vertices*)
  (maphash (lambda (k v)
             (when (equal (second k) graph-id)
               (print v)))
           *arcs*)
  t)


;;; -----------------------------------------------------------------------
;;; SSSP in Common Lisp
;;; -----------------------------------------------------------------------


;;; sssp-dist/2
;;; Restituisce la distanza corrente del vertice vertex-id nel grafo
;;; graph-id dalla sorgente, oppure NIL se non e' ancora stata calcolata.
(defun sssp-dist (graph-id vertex-id)
  (gethash (list 'dist graph-id vertex-id) *distances*))


;;; sssp-visited/2
;;; Restituisce T se il vertice vertex-id del grafo graph-id e' stato
;;; visitato durante l'esecuzione di Dijkstra, NIL altrimenti.
(defun sssp-visited (graph-id vertex-id)
  (gethash (list 'visited graph-id vertex-id) *visited*))


;;; sssp-previous/2
;;; Restituisce il predecessore del vertice vertex-id nel cammino
;;; minimo dalla sorgente, oppure NIL se non definito.
(defun sssp-previous (graph-id vertex-id)
  (gethash (list 'previous graph-id vertex-id) *previous*))


;;; sssp-change-dist/3
;;; Aggiorna la distanza del vertice vertex-id nel grafo graph-id
;;; con il valore new-dist.
(defun sssp-change-dist (graph-id vertex-id new-dist)
  (setf (gethash (list 'dist graph-id vertex-id) *distances*) new-dist))


;;; sssp-change-previous/3
;;; Aggiorna il predecessore del vertice vertex-v-id con vertex-u-id
;;; nel grafo graph-id.
(defun sssp-change-previous (graph-id vertex-v-id vertex-u-id)
  (setf (gethash (list 'previous graph-id vertex-v-id) *previous*)
        vertex-u-id))


;;; sssp-dijkstra/2
;;; Esegue l'algoritmo di Dijkstra sul grafo graph-id a partire dal
;;; vertice sorgente source-id. Al termine, le hash table *distances*,
;;; *previous* e *visited* contengono i risultati per ogni vertice.
;;; Restituisce NIL.
(defun sssp-dijkstra (graph-id source-id)
  (dijkstra graph-id source-id)
  nil)


;;; clear-graph-state/1
;;; Rimuove da *distances*, *visited* e *previous* solo le chiavi
;;; relative a graph-id, preservando i risultati di altri grafi.
(defun clear-graph-state (graph-id)
  (let ((keys-d '()) (keys-v '()) (keys-p '()))
    (maphash (lambda (k v) (declare (ignore v))
               (when (equal (second k) graph-id) (push k keys-d)))
             *distances*)
    (maphash (lambda (k v) (declare (ignore v))
               (when (equal (second k) graph-id) (push k keys-v)))
             *visited*)
    (maphash (lambda (k v) (declare (ignore v))
               (when (equal (second k) graph-id) (push k keys-p)))
             *previous*)
    (mapc (lambda (k) (remhash k *distances*)) keys-d)
    (mapc (lambda (k) (remhash k *visited*))   keys-v)
    (mapc (lambda (k) (remhash k *previous*))  keys-p)))


;;; dijkstra/2
;;; Funzione interna che esegue l'algoritmo di Dijkstra.
;;; Cancella solo i dati relativi a graph-id (non quelli di altri grafi),
;;; inizializza le distanze e avvia il ciclo principale tramite dijkstra-loop/2.
(defun dijkstra (graph-id source-id)
  (clear-graph-state graph-id)
  (new-heap graph-id)
  (let ((vertices (graph-vertices graph-id)))
    (initialize-graph graph-id source-id vertices)
    (dijkstra-loop graph-id (graph-vertices graph-id)))
  (heap-delete graph-id)
  t)


;;; dijkstra-loop/2
;;; Ciclo principale dell'algoritmo di Dijkstra. Ad ogni iterazione
;;; estrae il vertice con distanza minima dallo heap, lo marca come
;;; visitato e rilassa gli archi verso i suoi vicini non visitati.
(defun dijkstra-loop (graph-id vertices)
  (if (or (null vertices) (heap-empty graph-id))
      t
    (let* ((extracted  (heap-extract graph-id))
           (vertex-id  (second extracted))
           (remaining  (remove-vertex vertex-id vertices)))
      (setf (gethash (list 'visited graph-id vertex-id) *visited*) t)
      (let ((neighbors (graph-vertex-neighbors graph-id vertex-id)))
        (relaxation graph-id vertex-id neighbors))
      (dijkstra-loop graph-id remaining))))


;;; relaxation/3
;;; Per ogni vicino non ancora visitato di vertex-id, verifica se
;;; il cammino che passa per vertex-id offre una distanza migliore.
;;; In caso affermativo aggiorna *distances*, *previous* e la chiave
;;; nello heap tramite heap-find-key-by-value e heap-modify-key.
(defun relaxation (graph-id vertex-id neighbors)
  (cond
    ((null neighbors) t)
    ((sssp-visited graph-id (fourth (first neighbors)))
     (relaxation graph-id vertex-id (rest neighbors)))
    (t
     (let* ((neighbor  (fourth (first neighbors)))
            (weight    (fifth (first neighbors)))
            (dist-v    (sssp-dist graph-id vertex-id))
            (dist-n    (sssp-dist graph-id neighbor))
            (new-dist  (+ dist-v weight)))
       (when (< new-dist dist-n)
         (let ((old-key (heap-find-key-by-value graph-id neighbor)))
           (sssp-change-dist graph-id neighbor new-dist)
           (sssp-change-previous graph-id neighbor vertex-id)
           (heap-modify-key graph-id new-dist old-key neighbor)))
       (relaxation graph-id vertex-id (rest neighbors))))))


;;; initialize-graph/3
;;; Inizializza le distanze e inserisce tutti i vertici nello heap.
;;; La sorgente riceve distanza 0, tutti gli altri most-positive-double-float.
(defun initialize-graph (graph-id source-id vertices)
  (cond
    ((null vertices) t)
    ((equal source-id (third (first vertices)))
     (sssp-change-dist graph-id source-id 0)
     (heap-insert graph-id 0 source-id)
     (initialize-graph graph-id source-id (rest vertices)))
    (t
     (let ((v (third (first vertices))))
       (sssp-change-dist graph-id v most-positive-double-float)
       (sssp-change-previous graph-id v 'not-defined)
       (heap-insert graph-id most-positive-double-float v)
       (initialize-graph graph-id source-id (rest vertices))))))


;;; remove-vertex/2
;;; Rimuove il vertice vertex-id dalla lista vertices.
;;; Confronta vertex-id con il terzo elemento di ogni entry (vertex graph-id v).
(defun remove-vertex (vertex-id vertices)
  (remove-if (lambda (v) (equal (third v) vertex-id)) vertices))


;;; heap-find-key-by-value/2
;;; Cerca la chiave associata al valore value nello heap heap-id
;;; scorrendo l'array. Restituisce la chiave oppure NIL.
;;; (Rinominata da find-key per chiarezza; find-key era duplicato
;;; di heap-get-index ma con interfaccia diversa.)
(defun heap-find-key-by-value (heap-id value)
  (let* ((heap-rep (gethash heap-id *heaps*))
         (size     (heap-size heap-rep))
         (arr      (heap-actual-heap heap-rep)))
    (heap-find-key-by-value-aux arr size 0 value)))

(defun heap-find-key-by-value-aux (arr size i value)
  (if (= i size)
      nil
    (let ((entry (aref arr i)))
      (if (equal (second entry) value)
          (first entry)
        (heap-find-key-by-value-aux arr size (1+ i) value)))))


;;; sssp-shortest-path/3
;;; Restituisce la lista degli archi che costituiscono il cammino
;;; minimo da source-id a vertex-id nel grafo graph-id.
;;; Richiede che sssp-dijkstra/2 sia gia' stato eseguito.
;;; Se source-id e vertex-id coincidono, restituisce la lista vuota.
(defun sssp-shortest-path (graph-id source-id vertex-id)
  (if (equal source-id vertex-id)
      '()
    (path-list graph-id source-id vertex-id)))


;;; path-list/3
;;; Funzione ausiliaria di sssp-shortest-path/3. Ricostruisce
;;; ricorsivamente il cammino minimo risalendo la catena dei
;;; predecessori tramite sssp-previous/2.
(defun path-list (graph-id source-id vertex-id)
  (let ((prev (sssp-previous graph-id vertex-id)))
    (cond
      ((null prev)
       (format t "Path does not exist.~%")
       nil)
      ((equal prev 'not-defined)
       (format t "Path does not exist.~%")
       nil)
      ((equal prev source-id)
       (list (gethash (list 'arc graph-id source-id vertex-id) *arcs*)))
      (t
       (append (path-list graph-id source-id prev)
               (list (gethash (list 'arc graph-id prev vertex-id)
                              *arcs*)))))))


;;; -----------------------------------------------------------------------
;;; MinHeap in Common Lisp
;;; -----------------------------------------------------------------------

;;; Lo heap e' rappresentato come una lista
;;;   (heap heap-id size array)
;;; dove array e' un vettore di coppie (key value).
;;; La dimensione iniziale dell'array e' capacity (default 42)
;;; e viene raddoppiata automaticamente in caso di overflow.
;;;
;;; L'array e' creato con :adjustable t per permettere a heap-expand
;;; di usare adjust-array senza comportamenti undefined.


;;; is-heap/1
;;; Restituisce la rappresentazione dello heap heap-id se presente
;;; in *heaps*, NIL altrimenti.
(defun is-heap (heap-id)
  (gethash heap-id *heaps*))


;;; new-heap/1
;;; Crea un nuovo heap vuoto con identificatore heap-id e lo aggiunge
;;; a *heaps* se non e' gia' presente. L'array interno e' creato con
;;; :adjustable t per permettere l'uso di adjust-array in heap-expand.
(defun new-heap (heap-id &optional (capacity 42))
  (or (is-heap heap-id)
      (setf (gethash heap-id *heaps*)
            (list 'heap heap-id 0
                  (make-array capacity
                              :initial-element nil
                              :adjustable t)))))


;;; heap-id/1
;;; Restituisce l'identificatore dello heap dalla sua rappresentazione.
(defun heap-id (heap-rep)
  (second heap-rep))


;;; heap-size/1
;;; Restituisce il numero di elementi attualmente nello heap.
(defun heap-size (heap-rep)
  (third heap-rep))


;;; heap-actual-heap/1
;;; Restituisce l'array interno dello heap.
(defun heap-actual-heap (heap-rep)
  (fourth heap-rep))


;;; heap-delete/1
;;; Rimuove lo heap heap-id da *heaps*.
(defun heap-delete (heap-id)
  (remhash heap-id *heaps*))


;;; heap-empty/1
;;; Restituisce T se lo heap heap-id e' vuoto, NIL altrimenti.
(defun heap-empty (heap-id)
  (= 0 (heap-size (gethash heap-id *heaps*))))


;;; heap-not-empty/1
;;; Restituisce T se lo heap heap-id contiene almeno un elemento.
(defun heap-not-empty (heap-id)
  (not (heap-empty heap-id)))


;;; heap-head/1
;;; Restituisce la coppia (key value) dell'elemento con chiave minima
;;; (la radice dello heap), oppure NIL se lo heap e' vuoto.
(defun heap-head (heap-id)
  (if (heap-not-empty heap-id)
      (heap-get-value heap-id 0)
    nil))


;;; heap-insert/3
;;; Inserisce il valore value con chiave key nello heap heap-id.
;;; L'elemento viene aggiunto in fondo e risale tramite move-up/4
;;; per ripristinare la heap property. Se l'array e' pieno,
;;; viene espanso automaticamente.
(defun heap-insert (heap-id key value)
  (when (is-heap heap-id)
    (let* ((heap-rep (gethash heap-id *heaps*))
           (size     (heap-size heap-rep))
           (arr      (heap-actual-heap heap-rep)))
      (when (= size (array-total-size arr))
        (heap-expand heap-id))
      (move-up heap-id size key value)
      (heap-change-size heap-id 1)))
  t)


;;; move-up/4
;;; Inserisce la coppia (key value) nella posizione i dell'heap,
;;; risalendo verso la radice finche' la heap property e' soddisfatta.
(defun move-up (heap-id i key value)
  (if (and (> i 0)
           (> (first (heap-get-value heap-id (heap-parent i))) key))
      (progn
        (heap-set-value heap-id i
                        (heap-get-value heap-id (heap-parent i)))
        (move-up heap-id (heap-parent i) key value))
    (heap-set-value heap-id i (list key value))))


;;; heap-extract/1
;;; Estrae e restituisce la coppia (key value) con chiave minima
;;; (la radice dello heap). Ristruttura lo heap tramite heapify/2
;;; per ripristinare la heap property.
;;; Restituisce NIL se lo heap e' vuoto.
(defun heap-extract (heap-id)
  (if (heap-empty heap-id)
      nil
    (let ((head (heap-head heap-id)))
      (heap-change-size heap-id -1)
      (let ((size (heap-size (gethash heap-id *heaps*))))
        (if (= size 0)
            (heap-set-value heap-id 0 nil)
          (progn
            (heap-set-value heap-id 0 (heap-get-value heap-id size))
            (heap-set-value heap-id size nil)
            (heapify heap-id 0))))
      head)))


;;; heapify/2
;;; Fa scendere il nodo in posizione i nello heap, scambiandolo con
;;; il figlio di chiave minima finche' la heap property e' rispettata.
(defun heapify (heap-id i)
  (let* ((size    (heap-size (gethash heap-id *heaps*)))
         (left    (+ 1 (* 2 i)))
         (right   (+ 2 (* 2 i)))
         (k-curr  (first (heap-get-value heap-id i)))
         (k-left  (when (< left size)
                    (first (heap-get-value heap-id left))))
         (k-right (when (< right size)
                    (first (heap-get-value heap-id right)))))
    (cond
      ((null k-left) t)
      ((null k-right)
       (when (< k-left k-curr)
         (heap-swap heap-id i left)
         (heapify heap-id left)))
      (t
       (let ((min-child (if (<= k-left k-right) left right)))
         (when (< (first (heap-get-value heap-id min-child)) k-curr)
           (heap-swap heap-id i min-child)
           (heapify heap-id min-child)))))))


;;; heap-modify-key/4
;;; Modifica la chiave dell'elemento con coppia (old-key value) in
;;; new-key, ristrutturando lo heap per mantenere la heap property.
(defun heap-modify-key (heap-id new-key old-key value)
  (let ((i (heap-get-index heap-id 0 old-key value)))
    (when i
      (heap-set-value heap-id i (list new-key value))
      (move-up heap-id i new-key value)
      (let ((j (heap-get-index heap-id 0 new-key value)))
        (when j (heapify heap-id j)))))
  t)


;;; heap-parent/1
;;; Restituisce l'indice del genitore del nodo in posizione i.
(defun heap-parent (i)
  (floor (/ (1- i) 2)))


;;; heap-change-size/2
;;; Aggiorna la dimensione dello heap di amount (positivo o negativo).
(defun heap-change-size (heap-id amount)
  (let ((heap-rep (gethash heap-id *heaps*)))
    (setf (gethash heap-id *heaps*)
          (list 'heap heap-id
                (+ amount (heap-size heap-rep))
                (heap-actual-heap heap-rep)))))


;;; heap-expand/1
;;; Raddoppia la capacita' dell'array interno dello heap usando
;;; adjust-array (possibile perche' l'array e' stato creato con
;;; :adjustable t in new-heap).
(defun heap-expand (heap-id)
  (let* ((heap-rep (gethash heap-id *heaps*))
         (arr      (heap-actual-heap heap-rep))
         (new-size (* 2 (array-total-size arr)))
         (new-arr  (adjust-array arr new-size :initial-element nil)))
    (setf (gethash heap-id *heaps*)
          (list 'heap heap-id (heap-size heap-rep) new-arr))))


;;; heap-get-value/2
;;; Restituisce la coppia (key value) nella posizione i dell'heap.
(defun heap-get-value (heap-id i)
  (aref (heap-actual-heap (gethash heap-id *heaps*)) i))


;;; heap-set-value/3
;;; Imposta il valore nella posizione i dell'heap a value.
(defun heap-set-value (heap-id i value)
  (setf (aref (heap-actual-heap (gethash heap-id *heaps*)) i) value))


;;; heap-swap/3
;;; Scambia gli elementi nelle posizioni i e j dell'heap.
(defun heap-swap (heap-id i j)
  (let ((vi (heap-get-value heap-id i))
        (vj (heap-get-value heap-id j)))
    (heap-set-value heap-id i vj)
    (heap-set-value heap-id j vi)))


;;; heap-get-index/4
;;; Cerca nell'heap l'indice della coppia (key value) a partire
;;; dalla posizione i. Restituisce l'indice oppure NIL se non trovato.
(defun heap-get-index (heap-id i key value)
  (let ((size (heap-size (gethash heap-id *heaps*))))
    (if (>= i size)
        nil
      (let ((entry (heap-get-value heap-id i)))
        (if (and (equal (first entry) key)
                 (equal (second entry) value))
            i
          (heap-get-index heap-id (1+ i) key value))))))


;;; heap-print/1
;;; Stampa tutti gli elementi dello heap heap-id tramite la funzione
;;; ricorsiva ausiliaria heap-print-aux.
(defun heap-print (heap-id)
  (if (not (is-heap heap-id))
      (error "Heap ~A does not exist." heap-id)
    (let ((size (heap-size (gethash heap-id *heaps*))))
      (heap-print-aux heap-id 0 size)
      t)))

(defun heap-print-aux (heap-id i size)
  (if (= i size)
      t
    (progn
      (print (heap-get-value heap-id i))
      (heap-print-aux heap-id (1+ i) size))))


;;; -----------------------------------------------------------------------
;;; Test
;;; -----------------------------------------------------------------------

;;; test/1
;;; Costruisce il grafo di esempio con 6 vertici e 10 archi.
(defun test (graph-id)
  (new-graph graph-id)
  (new-vertex graph-id 'r)
  (new-vertex graph-id 's)
  (new-vertex graph-id 't)
  (new-vertex graph-id 'x)
  (new-vertex graph-id 'y)
  (new-vertex graph-id 'z)
  (new-arc graph-id 'r 's 5)
  (new-arc graph-id 'r 't 3)
  (new-arc graph-id 's 't 2)
  (new-arc graph-id 's 'x 3)
  (new-arc graph-id 't 'x 7)
  (new-arc graph-id 't 'y 4)
  (new-arc graph-id 't 'z 8)
  (new-arc graph-id 'x 'y 1)
  (new-arc graph-id 'x 'z 2)
  (new-arc graph-id 'y 'x 10)
  t)

;;; end of file sssp.lisp
