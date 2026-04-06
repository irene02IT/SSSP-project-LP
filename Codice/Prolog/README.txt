================================================================================
                   Single Source Shortest Paths (Prolog)
================================================================================

Autore:
    Irene E.


================================================================================
Introduzione
================================================================================

Questo progetto risolve il problema del Single Source Shortest Path (SSSP).
Dato un grafo diretto con archi a peso non negativo e un vertice sorgente,
calcola il cammino di costo minimo dalla sorgente verso ogni altro vertice
raggiungibile del grafo.

L'algoritmo utilizzato e' quello di Dijkstra, che opera su un MinHeap
come struttura dati di supporto per estrarre efficientemente il vertice
con distanza minima ad ogni iterazione.


================================================================================
Grafi in Prolog
================================================================================

Il grafo e' diretto e con archi a peso non negativo. La sua rappresentazione
nella base-dati Prolog si basa sull'asserzione dei seguenti predicati dinamici:

  graph/1
    Il predicato graph(G) e' vero se esiste un grafo identificato da G
    nella base-dati Prolog.

  vertex/2
    Il predicato vertex(G, V) e' vero se il vertice V appartiene al grafo G
    nella base-dati Prolog.

  arc/4
    Il predicato arc(G, U, V, Weight) e' vero se esiste un arco del grafo G
    che va da U a V con peso Weight nella base-dati Prolog.
    Weight puo' essere un intero o un float non negativo.


================================================================================
Interfaccia Prolog per la manipolazione dei grafi
================================================================================

  new_graph/1
  new_graph(G)

    Ha successo sempre. Se il grafo G non e' gia' presente nella base-dati,
    lo aggiunge tramite assert/1. Idempotente: se G esiste gia', non produce
    duplicati.


  delete_graph/1
  delete_graph(G)

    Elimina dalla base-dati il grafo G insieme a tutti i suoi vertici e archi.
    Verifica che G sia un grafo esistente, poi richiama retractall/1 per
    rimuovere il grafo, i suoi vertici e i suoi archi.


  new_vertex/2
  new_vertex(G, V)

    Ha successo sempre. Se il vertice V non e' gia' presente nel grafo G,
    lo aggiunge alla base-dati tramite assert/1. Idempotente: se V esiste
    gia', non produce duplicati.


  vertices/2
  vertices(G, Vs)

    Vero quando Vs e' la lista di tutti i vertici del grafo G.


  new_arc/3
  new_arc(G, U, V)

    Variante di new_arc/4 con peso di default pari a 1.


  new_arc/4
  new_arc(G, U, V, Weight)

    Aggiunge alla base-dati l'arco da U a V con peso Weight nel grafo G.
    Se i vertici U o V non esistono, vengono creati implicitamente tramite
    new_vertex/2. Se l'arco esiste gia', viene sostituito con il nuovo peso.
    Fallisce se Weight < 0 o se il grafo G non esiste.
    Weight puo' essere un intero o un float non negativo.


  arcs/2
  arcs(G, Es)

    Vero quando Es e' la lista di tutti gli archi del grafo G,
    nella forma arc(G, U, V, Weight).


  neighbors/3
  neighbors(G, V, Ns)

    Vero quando V e' un vertice di G e Ns e' la lista degli archi
    arc(G, V, N, W) che partono da V verso i suoi vicini diretti.


  list_graph/1
  list_graph(G)

    Stampa sulla console Prolog tutti i vertici e tutti gli archi del grafo G,
    utilizzando listing/1.


  list_arcs/1
  list_arcs(G)

    Stampa sulla console Prolog tutti gli archi del grafo G,
    utilizzando listing/1.


  list_vertices/1
  list_vertices(G)

    Stampa sulla console Prolog tutti i vertici del grafo G,
    utilizzando listing/1.


================================================================================
SSSP in Prolog
================================================================================

Il predicato dijkstra_sssp/2 prende in input un grafo e un vertice sorgente
e asserisce nella base-dati tutti i fatti necessari a determinare il cammino
di peso minimo dalla sorgente verso ogni altro vertice del grafo.
Il cammino minimo viene poi restituito dal predicato shortest_path/4.

Due esecuzioni consecutive di dijkstra_sssp/2, anche su grafi diversi, sono
indipendenti: ogni esecuzione azzera i fatti distance/3, visited/2 e
previous/3 lasciati dalla precedente prima di procedere.

I predicati dinamici utilizzati durante l'esecuzione dell'algoritmo sono:

  distance/3
    Il predicato distance(G, V, D) e' vero se la distanza minima del vertice V
    del grafo G dalla sorgente e' D. Il valore D puo' essere un numero non
    negativo oppure l'atomo inf, che rappresenta la distanza infinita
    (vertice non raggiungibile dalla sorgente).

  visited/2
    Il predicato visited(G, V) e' vero se il vertice V del grafo G e' stato
    visitato durante l'esecuzione dell'algoritmo di Dijkstra.

  previous/3
    Il predicato previous(G, V, U) e' vero se U e' il vertice precedente a V
    nel cammino minimo dalla sorgente a V. Il valore U puo' essere un vertice
    del grafo oppure l'atomo not_defined, assegnato durante l'inizializzazione
    a tutti i vertici diversi dalla sorgente.


================================================================================
Interfaccia Prolog per l'esecuzione del SSSP
================================================================================

  change_distance/3
  change_distance(G, V, NewDist)

    Ritira dalla base-dati tutte le istanze di distance(G, V, _) e asserisce
    il fatto distance(G, V, NewDist).


  change_previous/3
  change_previous(G, V, U)

    Ritira dalla base-dati tutte le istanze di previous(G, V, _) e asserisce
    il fatto previous(G, V, U).


  dijkstra_sssp/2
  dijkstra_sssp(G, Source)

    Risolve il problema SSSP sul grafo G a partire dal vertice sorgente Source,
    applicando l'algoritmo di Dijkstra. Al termine della sua esecuzione, la
    base-dati contiene i fatti distance/3, previous/3 e visited/2 per ogni
    vertice di G.

    Il predicato opera come segue: elimina tutti i fatti distance/3, visited/2
    e previous/3 preesistenti, crea lo heap di supporto, invoca
    initialize_single_source/3 per la fase di inizializzazione, esegue
    dijkstra/2 e infine elimina lo heap utilizzato.


  dijkstra/2
  dijkstra(G, ListaV)

    Ciclo principale dell'algoritmo di Dijkstra. Ad ogni passo estrae il
    vertice con distanza minima dallo heap tramite extract/3, lo marca come
    visitato e invoca passo_di_rilassamento/3 per aggiornare le distanze
    verso i vicini non ancora visitati.


  passo_di_rilassamento/3
  passo_di_rilassamento(G, V, ListaT)

    Per ogni vertice T nella lista ListaT (vicini non visitati di V),
    verifica se il cammino che passa per V offre una distanza migliore
    rispetto a quella corrente di T. In caso affermativo, aggiorna
    distance/3 e previous/3 tramite change_distance/3 e change_previous/3,
    e aggiorna la chiave di T nello heap tramite modify_key/4.


  initialize_single_source/3
  initialize_single_source(G, Source, ListaV)

    Fase di inizializzazione dell'algoritmo. Assegna distanza 0 alla sorgente
    Source e distanza inf a tutti gli altri vertici, inserendo ciascuno nello
    heap con la rispettiva chiave. Per i vertici diversi dalla sorgente
    asserisce anche previous(G, V, not_defined).


  vertex_neighbors/3
  vertex_neighbors(G, V, Ns)

    Vero quando Ns e' la lista dei vertici direttamente raggiungibili da V
    nel grafo G che non sono ancora stati visitati.


  remove/3
  remove(List1, List2, Ris)

    Vero quando Ris e' la lista ottenuta rimuovendo da List1 tutti gli
    elementi che compaiono in List2.


  shortest_path/4
  shortest_path(G, Source, V, Path)

    Vero quando Path e' la lista ordinata degli archi
        [arc(G, Source, N1, W1), arc(G, N1, N2, W2), ..., arc(G, NK, V, Wk)]
    che rappresenta il cammino minimo da Source a V nel grafo G.
    Richiede che dijkstra_sssp/2 sia stato eseguito in precedenza con
    sorgente Source.

    Se Source e V coincidono, restituisce il cammino vuoto [].
    Se V non e' raggiungibile da Source, il predicato fallisce.
    Delega la costruzione del cammino a list_path/4.


  list_path/4
  list_path(G, Source, V, Path)

    Predicato ausiliario di shortest_path/4. Ricostruisce ricorsivamente il
    cammino minimo da Source a V risalendo la catena dei predecessori tramite
    previous/3, dal vertice di destinazione V fino alla sorgente Source.
    Fallisce se il cammino non esiste (vertice non raggiungibile).


================================================================================
MinHeap in Prolog
================================================================================

Un MinHeap e' un albero binario quasi completo in cui ogni nodo ha chiave
minore o uguale a quella dei propri figli (heap property). Di conseguenza,
la radice contiene sempre l'elemento con chiave minima.

La struttura e' rappresentata nella base-dati Prolog tramite i seguenti
predicati dinamici:

  heap/2
    Il predicato heap(H, S) e' vero se esiste uno heap identificato da H
    con S elementi nella base-dati Prolog.

  heap_entry/4
    Il predicato heap_entry(H, P, K, V) e' vero se nello heap H esiste
    un nodo in posizione P con chiave K e valore V.

Le chiavi possono essere numeri non negativi (interi o float) oppure l'atomo
inf, che rappresenta la distanza infinita. I predicati ausiliari inf_leq/2,
inf_lt/2 e inf_add/3 gestiscono i confronti e le somme che coinvolgono inf.


================================================================================
Interfaccia Prolog per la manipolazione dello heap
================================================================================

  new_heap/1
  new_heap(H)

    Aggiunge un nuovo heap H vuoto alla base-dati, se non e' gia' presente.


  new_heap/2
  new_heap(H, S)

    Aggiunge un nuovo heap H con dimensione iniziale S alla base-dati,
    se non e' gia' presente.


  delete_heap/1
  delete_heap(H)

    Rimuove dalla base-dati lo heap H e tutti i suoi elementi heap_entry/4.


  heap_size/2
  heap_size(H, S)

    Vero quando S e' il numero di elementi attualmente contenuti nello heap H.


  empty/1
  empty(H)

    Vero quando lo heap H non contiene alcun elemento.


  not_empty/1
  not_empty(H)

    Vero quando lo heap H contiene almeno un elemento.
    Implementato come negazione di empty/1.


  head/3
  head(H, K, V)

    Vero quando l'elemento in cima allo heap H (quello con chiave minima)
    ha chiave K e valore V.


  insert/3
  insert(H, K, V)

    Inserisce il valore V nello heap H con chiave K. L'elemento viene
    aggiunto in fondo e poi fatto risalire tramite bubble/2 per ripristinare
    la heap property.


  list_heap/1
  list_heap(H)

    Stampa sulla console Prolog lo stato interno dello heap H,
    mostrando tutti i fatti heap_entry/4 tramite listing/1.


  bubble/2
  bubble(H, P)

    Risale nello heap a partire dalla posizione P, scambiando il nodo
    corrente con il padre fintanto che la chiave del padre e' strettamente
    maggiore. Garantisce la heap property dopo un inserimento.
    Gestisce correttamente l'atomo inf come chiave.


  extract/3
  extract(H, K, V)

    Rimuove dallo heap H l'elemento con chiave minima, unificando K e V
    con la sua chiave e il suo valore. Lo heap viene poi ristrutturato
    tramite min_heapify/2 per ripristinare la heap property.


  min_heapify/2
  min_heapify(H, P)

    Fa scendere il nodo in posizione P nello heap, scambiandolo con il
    figlio di chiave minima fintanto che la heap property non e' soddisfatta.
    Gestisce correttamente l'atomo inf come chiave.


  scambio/3
  scambio(H, P1, P2)

    Scambia i nodi nelle posizioni P1 e P2 dello heap H, aggiornando
    i corrispondenti fatti heap_entry/4 nella base-dati.


  modify_key/4
  modify_key(H, NewKey, OldKey, V)

    Sostituisce la chiave OldKey associata al valore V con la nuova chiave
    NewKey. La posizione del nodo viene determinata tramite retract/1, che
    unifica direttamente la variabile di posizione P garantendone
    l'istanziazione. Lo heap viene poi ristrutturato tramite bubble/2 e
    min_heapify/2 per ripristinare la heap property.


================================================================================
Esempio di utilizzo
================================================================================

    ?- ['sssp.pl'].
    true.

    ?- test(g1).
    true.

    ?- dijkstra_sssp(g1, r).
    true.

    ?- shortest_path(g1, r, z, Path).
    Path = [arc(g1, r, s, 5), arc(g1, s, x, 3), arc(g1, x, z, 2)].

    ?- shortest_path(g1, r, y, Path).
    Path = [arc(g1, r, t, 3), arc(g1, t, y, 4)].

    ?- shortest_path(g1, r, r, Path).
    Path = [].

================================================================================