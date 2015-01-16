#ifndef _vector_h_
#define _vector_h_

/* C code and macros for VECTOR objects similar to C++ std::vector */
#include <stddef.h>

#define CAT(A,B)	A##B
#define VECTOR(NAME)	CAT(NAME,_VECTOR)
#define DECLARE_VECTOR(TYPE)		\
typedef struct {			\
    int		capacity, size;		\
    TYPE	*data;			\
} CAT(TYPE,_VECTOR);
#define DECLARE_VECTOR2(NAME, ELTYPE) 	\
typedef struct {			\
    int		capacity, size;		\
    ELTYPE	*data;			\
} CAT(NAME,_VECTOR);
#define DECLARE_VECTOR3(NAME, ELTYPE, EXTRA) 	\
typedef struct {			\
    int		capacity, size;		\
    ELTYPE	*data;			\
    EXTRA                               \
} CAT(NAME,_VECTOR);

#define RAW(X)		X

/* VECTOR constructors/destrutor
 * can safely use memset(&vec, 0, sizeof(vec)) for initial capacity of 0,
 * so global and calloc'd VECTORs are safe to use immediately
 * local and malloc's VECTORs must be initialized before use, as they may
 * contain garbage */

/* VECTOR_init(vec, capacity)
 *   initialize an empty vector with optional initial capacity
 * VECTOR_initcopy(vec, from)
 *   initialize a vector as a copy of an existing vector
 * VECTOR_initN(vec, val1, ...)
 *   initialize a vector with N values
 * RETURNS
 *   0  success
 *   -1 failure (out of memory), vector has capacity 0
 */
#define VECTOR_init(vec, ...) \
    init_raw_vector(&(vec), sizeof((vec).data[0]), RAW(__VA_ARGS__+0))

#define VECTOR_initcopy(vec, from) \
    (init_raw_vector(&(vec), sizeof((vec).data[0]), (from).size) ? -1 :	\
     (memcpy((vec).data, (from).data,					\
	     ((vec).size = (from).size) * sizeof((vec).data[0])), 0))

#define VECTOR_init1(vec, v1) \
    (init_raw_vector(&(vec), sizeof((vec).data[0]), 1) ? -1 : \
     ((vec).size = 1, (vec).data[0] = (v1), 0))
#define VECTOR_init2(vec, v1, v2) \
    (init_raw_vector(&(vec), sizeof((vec).data[0]), 2) ? -1 : \
     ((vec).size = 2, (vec).data[0] = (v1), (vec).data[1] = (v2), 0))
#define VECTOR_init3(vec, v1, v2, v3) \
    (init_raw_vector(&(vec), sizeof((vec).data[0]), 3) ? -1 : \
     ((vec).size = 3, (vec).data[0] = (v1), (vec).data[1] = (v2), \
      (vec).data[2] = (v3), 0))
#define VECTOR_init4(vec, v1, v2, v3, v4) \
    (init_raw_vector(&(vec), sizeof((vec).data[0]), 4) ? -1 : \
     ((vec).size = 3, (vec).data[0] = (v1), (vec).data[1] = (v2), \
      (vec).data[2] = (v3), (vec).data[3] = (v4), 0))
#define VECTOR_init5(vec, v1, v2, v3, v4, v5) \
    (init_raw_vector(&(vec), sizeof((vec).data[0]), 5) ? -1 : \
     ((vec).size = 3, (vec).data[0] = (v1), (vec).data[1] = (v2), \
      (vec).data[2] = (v3), (vec).data[3] = (v4), (vec).data[4] = (v5), 0))

#define EMPTY_VECTOR_INIT       { 0, 0, 0 }

/* VECTOR_fini(vec)
 *   destroys a vector, freeing memory
 * RETURNS
 *   void
 */
#define VECTOR_fini(vec)	free((vec).data)

/* VECTOR methods */

/* VECTOR_add(vec, val)
 *   add a single value to the end of a vector, increasing its size (and
 *   capacity if necessary)
 * VECTOR_addcopy(vec, ptr, n)
 *   add a multiple value to the end of a vector, increasing its size (and
 *   capacity as necessary)
 * VECTOR_copy(vec, from)
 *   replace a vector with a copy of another vector
 * RETURNS
 *   0  success
 *   -1 failure (out of memory), vector is unchanged
 */
#define VECTOR_add(vec, val) \
    (((vec).size == (vec).capacity &&				\
      expand_raw_vector(&(vec), sizeof((vec).data[0])))	? -1 :	\
     ((vec).data[(vec).size++] = (val), 0))
#define VECTOR_addcopy(vec, ptr, n) \
    (VECTOR_reserve(vec, (vec).size + (n)) ? -1 : (	\
     memcpy((vec).data + (vec).size, (ptr), (n) * sizeof((vec).data[0])), \
     (vec).size += (n), 0))
#define VECTOR_copy(vec, from) \
    (VECTOR_reserve(vec, (from).size) ? -1 : (	\
     memcpy((vec).data, (from).data, (from).size * sizeof((vec).data[0])), \
     (vec).size = (from).size, 0))

#define VECTOR_begin(vec)	((vec).data)
#define VECTOR_end(vec)		((vec).data + (vec).size)
#define VECTOR_empty(vec)	((vec).size == 0)

/* VECTOR_erase(vec, idx, cnt)
 *   erase cnt elements from a vector (defaults to 1).  If there are fewer
 *   than cnt elements in the vector after idx (inclusive), all will be
 *   erased
 * RETURNS
 *   0  success
 *   -1 idx is out of range
 */
#define VECTOR_erase(vec, idx, ...) \
    erase_raw_vector(&(vec), sizeof((vec).data[0]), idx, RAW(__VA_ARGS__+0))

/* VECTOR_expand(vec)
 *   increase the capacity of a vector, if possible.  Does not affect the size
 * RETURNS
 *   0  success
 *   -1 failure (out of memory), vector is unchanged
 */
#define VECTOR_expand(vec) expand_raw_vector(&(vec), sizeof((vec).data[0]))

/* VECTOR_foreach(vec, apply)
 *   apply a function or macro to every element of a vector
 *   not a valid expression, so doesn't really return anything
 */
#define VECTOR_foreach(vec, apply) do { \
    for (int i_ = 0; i_ < (vec).size; i_++) { apply((&(vec).data[i_])); } \
} while(0)

/* VECTOR_insert(vec, idx, cnt)
 *   increase the size of a vector, adding uninitialized space at idx, and
 *   moving later elements of the vector up.  cnt defaults to 1
 * RETURNS
 *   0  success
 *   -1 failure -- idx is out of range[ERANGE], or out of memeory[ENOMEM]
 *                 vector is unchanged
 */
#define VECTOR_insert(vec, idx, ...) \
    insert_raw_vector(&(vec), sizeof((vec).data[0]), idx, RAW(__VA_ARGS__+0))

#define VECTOR_pop(vec)		((vec).data[--(vec).size])
#define VECTOR_push(vec, val)	VECTOR_add(vec, val)

/* VECTOR_reserve(vec, size, shrink)
 *   change the capacity of a vector.  If shrink is false (default), will only
 *   increase the capacity.
 * RETURNS
 *   0  success
 *   -1 failure (out of memory), vector is unchanged
 */
#define VECTOR_reserve(vec, size, ...) \
    reserve_raw_vector(&(vec), sizeof((vec).data[0]), size, RAW(__VA_ARGS__+0))

/* VECTOR_resize(vec, size, shrink)
 *   change the size of a vector.  If shrink is false (default), will only
 *   increase the capacity.
 * RETURNS
 *   0  success
 *   -1 failure (out of memory), vector is unchanged
 */
#define VECTOR_resize(vec, sz, ...) \
    (VECTOR_reserve(vec, sz, __VA_ARGS__) ? -1 : ((vec).size = (sz), 0))

/* VECTOR_shrink_to_fit(vec)
 *   reduce capacity to match the size, releasing memory if possible
 * RETURNS
 *   0  success
 *   -1 failure (realloc failed to shrink?), vector is unchanged
 */
#define VECTOR_shrink_to_fit(vec) \
    shrink_raw_vector(&(vec), sizeof((vec).data[0]))

/* VECTOR_terminate(vec, val)
 *   ensure that capacity is greater than size, and store val after
 *   the end of the vector.
 * RETURNS
 *   0  success
 *   -1 failure (out of memory), vector is unchanged
 */
#define VECTOR_terminate(vec, val) \
    (((vec).size == (vec).capacity &&				\
      expand_raw_vector(&(vec), sizeof((vec).data[0])))	? -1 :	\
     ((vec).data[(vec).size] = (val), 0))
#define VECTOR_top(vec)		((vec).data[(vec).size-1])

extern int erase_raw_vector(void *vec, size_t elsize, int idx, unsigned cnt);
extern int expand_raw_vector(void *vec, size_t elsize);
extern int init_raw_vector(void *vec, size_t elsize, int mincap);
extern int insert_raw_vector(void *vec, size_t elsize, int idx, unsigned cnt);
extern int reserve_raw_vector(void *vec, size_t elsize, int size, int shrink);
extern int shrink_raw_vector(void *vec, size_t elsize);

#endif /* _vector_h_ */
