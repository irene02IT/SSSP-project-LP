================================================================================
                   Single Source Shortest Paths (Common Lisp)
================================================================================

Autori:
    Irene E.


================================================================================
Introduzione
================================================================================

Questo programma risolve il problema del Single Source Shortest Path (SSSP).
Dato un grafo diretto con archi a peso non negativo e un vertice sorgente,
calcola il cammino di costo minimo dalla sorgente verso ogni altro vertice
raggiungibile del grafo.

L'algoritmo utilizzato e' quello di Dijkstra, che si appoggia su un MinHeap
come struttura dati di supporto per estrarre efficientemente il vertice con
distanza minima ad ogni iterazione.


================================================================================
Strutture dati
================================================================================

Tutte le informazioni del grafo e dell'algoritmo sono mantenute in hash table
con test di uguaglianza #'equal:

  *graphs*    -- associa ogni graph-id al suo identificatore
  *vertices*  -- associa (vertex graph-id vertex-id) alla sua rappresentazione
  *arcs*      -- associa (arc graph-id u v) alla sua rappresentazione completa
  *visited*   -- associa (visited graph-id vertex-id) a T se visitato
  *distances* -- associa (dist graph-id vertex-id) alla distanza corrente
  *previous*  -- associa (previous graph-id vertex-id) al suo predecessore
  *heaps*     -- associa heap-id alla sua rappresentazione (heap id size array)

Le hash table *distances*, *visited* e *previous* sono condivise tra tutti i
grafi: ogni chiamata a sssp-dijkstra cancella solo le chiavi relative al
grafo corrente, preservando i risultati di eventuali esecuzioni precedenti
su grafi diversi.


================================================================================
Interfaccia Common Lisp per la manipolazione dei grafi
================================================================================

  (new-graph graph-id)
    Aggiunge graph-id al sistema se non e' gia' presente.
    Idempotente: restituisce sempre graph-id.

  (is-graph graph-id)
    Restituisce graph-id se il grafo e' presente, NIL altrimenti.

  (delete-graph graph-id)
    Elimina il grafo graph-id dal sistema insieme a tutti i suoi vertici
    e archi. Raccoglie prima le chiavi da rimuovere, poi le elimina:
    modificare una hash-table durante l'iterazione con maphash e' undefined
    behavior in Common Lisp. Restituisce T.

  (new-vertex graph-id vertex-id)
    Aggiunge vertex-id al grafo graph-id se non e' gia' presente.
    Idempotente: restituisce sempre (vertex graph-id vertex-id).

  (is-vertex graph-id vertex-id)
    Restituisce (vertex graph-id vertex-id) se il vertice e' presente,
    NIL altrimenti.

  (graph-vertices graph-id)
    Restituisce la lista di tutti i vertici del grafo graph-id nella forma
    (vertex graph-id vertex-id).

  (new-arc graph-id vertex-1-id vertex-2-id &optional weight)
    Aggiunge al grafo graph-id l'arco da vertex-1-id a vertex-2-id con
    peso weight (default 1). Se l'arco esiste gia', viene sostituito con
    il nuovo peso. Weight puo' essere un intero o un float non negativo.
    Restituisce (arc graph-id u v weight).

  (is-arc graph-id vertex-1-id vertex-2-id)
    Restituisce (arc graph-id u v weight) se l'arco e' presente,
    NIL altrimenti.

  (graph-arcs graph-id)
    Restituisce la lista di tutti gli archi del grafo graph-id nella forma
    (arc graph-id u v weight).

  (graph-vertex-neighbors graph-id vertex-id)
    Restituisce la lista degli archi uscenti da vertex-id nel grafo graph-id.

  (graph-print graph-id)
    Stampa tutti i vertici e gli archi del grafo graph-id.


================================================================================
SSSP in Common Lisp
================================================================================

  (sssp-dist graph-id vertex-id)
    Restituisce la distanza corrente di vertex-id dalla sorgente nel grafo
    graph-id, oppure NIL se non ancora calcolata.

  (sssp-visited graph-id vertex-id)
    Restituisce T se vertex-id e' stato visitato durante l'esecuzione di
    Dijkstra, NIL altrimenti.

  (sssp-previous graph-id vertex-id)
    Restituisce il predecessore di vertex-id nel cammino minimo dalla
    sorgente, oppure NIL se non ancora definito.

  (sssp-change-dist graph-id vertex-id new-dist)
    Aggiorna la distanza di vertex-id nel grafo graph-id con new-dist.

  (sssp-change-previous graph-id vertex-v-id vertex-u-id)
    Imposta vertex-u-id come predecessore di vertex-v-id nel grafo graph-id.

  (sssp-dijkstra graph-id source-id)
    Esegue l'algoritmo di Dijkstra sul grafo graph-id a partire dalla
    sorgente source-id. Cancella solo i dati relativi a graph-id prima
    di procedere, preservando i risultati di altri grafi gia' calcolati.
    Al termine, *distances*, *previous* e *visited* contengono i risultati
    per ogni vertice del grafo. Restituisce NIL.

  (dijkstra graph-id source-id)
    Funzione interna che coordina l'esecuzione dell'algoritmo:
      1. Cancella i dati di graph-id tramite clear-graph-state.
      2. Crea lo heap di supporto.
      3. Inizializza le distanze tramite initialize-graph.
      4. Esegue il ciclo principale tramite dijkstra-loop.
      5. Elimina lo heap al termine.

  (clear-graph-state graph-id)
    Rimuove da *distances*, *visited* e *previous* solo le chiavi relative
    a graph-id, preservando i risultati di tutti gli altri grafi.

  (dijkstra-loop graph-id vertices)
    Ciclo principale dell'algoritmo. Ad ogni iterazione estrae il vertice
    con distanza minima dallo heap, lo marca come visitato e rilassa gli
    archi verso i suoi vicini non ancora visitati.

  (relaxation graph-id vertex-id neighbors)
    Per ogni vicino non visitato di vertex-id, verifica se il cammino che
    passa per vertex-id offre una distanza migliore. In caso affermativo
    aggiorna *distances*, *previous* e la chiave nello heap tramite
    heap-find-key-by-value e heap-modify-key.

  (initialize-graph graph-id source-id vertices)
    Inizializza le distanze: 0 per source-id,
    MOST-POSITIVE-DOUBLE-FLOAT per tutti gli altri. Inserisce ogni vertice
    nello heap con la rispettiva chiave e imposta il predecessore a
    'not-defined per i non-sorgenti.

  (remove-vertex vertex-id vertices)
    Rimuove vertex-id dalla lista vertices. Utilizzata internamente da
    dijkstra-loop dopo la visita di un nodo.

  (heap-find-key-by-value heap-id value)
    Cerca la chiave associata al valore value nello heap heap-id scorrendo
    l'array. Restituisce la chiave oppure NIL.

  (sssp-shortest-path graph-id source-id vertex-id)
    Restituisce la lista degli archi che costituiscono il cammino minimo
    da source-id a vertex-id nel grafo graph-id.
    Richiede che sssp-dijkstra sia gia' stato eseguito con sorgente source-id.
    Se source-id e vertex-id coincidono, restituisce la lista vuota '().
    Se vertex-id non e' raggiungibile, restituisce NIL.

  (path-list graph-id source-id vertex-id)
    Funzione ausiliaria di sssp-shortest-path. Ricostruisce ricorsivamente
    il cammino minimo risalendo la catena dei predecessori tramite
    sssp-previous, dal vertice di destinazione fino alla sorgente.


================================================================================
MinHeap in Common Lisp
================================================================================

Un MinHeap e' un albero binario quasi completo in cui ogni nodo ha chiave
minore o uguale a quella dei propri figli. La radice contiene sempre l'elemento
con chiave minima. Lo heap e' rappresentato come una lista:

    (heap heap-id size array)

dove array e' un vettore di coppie (key value). La capacita' iniziale e' 42
e viene raddoppiata automaticamente con adjust-array in caso di overflow.
L'array e' creato con :adjustable t per rendere lecita questa operazione.

  (new-heap heap-id &optional capacity)
    Crea un nuovo heap vuoto con identificatore heap-id. La capacita'
    iniziale e' 42 se non specificata. L'array e' :adjustable t.
    Restituisce la rappresentazione dello heap.

  (is-heap heap-id)
    Restituisce la rappresentazione dello heap se presente, NIL altrimenti.

  (heap-delete heap-id)
    Rimuove heap-id dalla hash table *heaps*.

  (heap-empty heap-id)
    Restituisce T se lo heap e' vuoto, NIL altrimenti.

  (heap-not-empty heap-id)
    Restituisce T se lo heap contiene almeno un elemento.

  (heap-head heap-id)
    Restituisce la coppia (key value) con chiave minima senza rimuoverla,
    oppure NIL se lo heap e' vuoto.

  (heap-insert heap-id key value)
    Inserisce (key value) nello heap. L'elemento viene aggiunto in fondo
    e risale tramite move-up per ripristinare la heap property.
    L'array viene espanso automaticamente tramite heap-expand se necessario.

  (move-up heap-id i key value)
    Inserisce (key value) in posizione i, risalendo verso la radice
    finche' la heap property e' soddisfatta.

  (heap-extract heap-id)
    Estrae e restituisce la coppia (key value) con chiave minima.
    Ristruttura lo heap tramite heapify per ripristinare la heap property.
    Restituisce NIL se lo heap e' vuoto.

  (heapify heap-id i)
    Fa scendere il nodo in posizione i, scambiandolo con il figlio di
    chiave minima finche' la heap property e' soddisfatta.

  (heap-modify-key heap-id new-key old-key value)
    Modifica la chiave dell'elemento con coppia (old-key value) in new-key,
    ristrutturando lo heap tramite move-up e heapify.

  (heap-parent i)
    Restituisce l'indice del genitore del nodo in posizione i.

  (heap-change-size heap-id amount)
    Aggiorna la dimensione dello heap di amount (positivo o negativo).

  (heap-expand heap-id)
    Raddoppia la capacita' dell'array interno dello heap tramite adjust-array.

  (heap-get-value heap-id i)
    Restituisce la coppia (key value) nella posizione i dello heap.

  (heap-set-value heap-id i value)
    Imposta il valore nella posizione i dello heap.

  (heap-swap heap-id i j)
    Scambia gli elementi nelle posizioni i e j dello heap.

  (heap-get-index heap-id i key value)
    Restituisce l'indice della coppia (key value) nello heap a partire
    dalla posizione i, oppure NIL se non trovata.

  (heap-print heap-id)
    Stampa tutti gli elementi dello heap heap-id tramite la funzione
    ricorsiva ausiliaria heap-print-aux.


================================================================================
Esempio di utilizzo
================================================================================

    CL-USER> (load "sssp.lisp")
    T

    CL-USER> (test 'g1)
    T

    CL-USER> (sssp-dijkstra 'g1 'r)
    NIL

    CL-USER> (sssp-shortest-path 'g1 'r 'z)
    ((ARC G1 R S 5) (ARC G1 S X 3) (ARC G1 X Z 2))

    CL-USER> (sssp-shortest-path 'g1 'r 'y)
    ((ARC G1 R T 3) (ARC G1 T Y 4))

    CL-USER> (sssp-shortest-path 'g1 'r 'r)
    NIL

================================================================================