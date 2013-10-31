/*
 * Copyright (c) 2007-2013 Scott Lembcke and Howling Moon Software
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
module dchip.spatial_index;

import dchip.bb;
import dchip.bb_tree;
import dchip.chipmunk;
import dchip.space_hash;
import dchip.sweep1D;
import dchip.types;

/**
    Spatial indexes are data structures that are used to accelerate collision detection
    and spatial queries. Chipmunk provides a number of spatial index algorithms to pick from
    and they are programmed in a generic way so that you can use them for holding more than
    just cpShape structs.

    It works by using void pointers to the objects you add and using a callback to ask your code
    for bounding boxes when it needs them. Several types of queries can be performed an index as well
    as reindexing and full collision information. All communication to the spatial indexes is performed
    through callback functions.

    Spatial indexes should be treated as opaque structs.
    This meanns you shouldn't be reading any of the struct fields.
*/

/// Spatial index bounding box callback function type.
/// The spatial index calls this function and passes you a pointer to an object you added
/// when it needs to get the bounding box associated with that object.
alias cpSpatialIndexBBFunc = cpBB function(void* obj);

/// Spatial index/object iterator callback function type.
alias cpSpatialIndexIteratorFunc = void function(void* obj, void* data);

/// Spatial query callback function type.
alias cpSpatialIndexQueryFunc = cpCollisionID function(void* obj1, void* obj2, cpCollisionID id, void* data);

/// Spatial segment query callback function type.
alias cpSpatialIndexSegmentQueryFunc = cpFloat function(void* obj1, void* obj2, void* data);

///
package struct cpSpatialIndex
{
    cpSpatialIndexClass* klass;
    cpSpatialIndexBBFunc bbfunc;
    cpSpatialIndex* staticIndex;
    cpSpatialIndex* dynamicIndex;
}

/// Allocate a spatial hash.
cpSpaceHash* cpSpaceHashAlloc();

/// Initialize a spatial hash.
cpSpatialIndex* cpSpaceHashInit(cpSpaceHash* hash, cpFloat celldim, int numcells, cpSpatialIndexBBFunc bbfunc, cpSpatialIndex* staticIndex);

/// Allocate and initialize a spatial hash.
cpSpatialIndex* cpSpaceHashNew(cpFloat celldim, int cells, cpSpatialIndexBBFunc bbfunc, cpSpatialIndex* staticIndex);

/// Change the cell dimensions and table size of the spatial hash to tune it.
/// The cell dimensions should roughly match the average size of your objects
/// and the table size should be ~10 larger than the number of objects inserted.
/// Some trial and error is required to find the optimum numbers for efficiency.
void cpSpaceHashResize(cpSpaceHash* hash, cpFloat celldim, int numcells);

/// Allocate a bounding box tree.
cpBBTree* cpBBTreeAlloc();

/// Initialize a bounding box tree.
cpSpatialIndex* cpBBTreeInit(cpBBTree* tree, cpSpatialIndexBBFunc bbfunc, cpSpatialIndex* staticIndex);

/// Allocate and initialize a bounding box tree.
cpSpatialIndex* cpBBTreeNew(cpSpatialIndexBBFunc bbfunc, cpSpatialIndex* staticIndex);

/// Perform a static top down optimization of the tree.
void cpBBTreeOptimize(cpSpatialIndex* index);

/// Bounding box tree velocity callback function.
/// This function should return an estimate for the object's velocity.
alias cpBBTreeVelocityFunc = cpVect function(void* obj);

/// Set the velocity function for the bounding box tree to enable temporal coherence.
void cpBBTreeSetVelocityFunc(cpSpatialIndex* index, cpBBTreeVelocityFunc func);

/// Allocate a 1D sort and sweep broadphase.
cpSweep1D* cpSweep1DAlloc();

/// Initialize a 1D sort and sweep broadphase.
cpSpatialIndex* cpSweep1DInit(cpSweep1D* sweep, cpSpatialIndexBBFunc bbfunc, cpSpatialIndex* staticIndex);

/// Allocate and initialize a 1D sort and sweep broadphase.
cpSpatialIndex* cpSweep1DNew(cpSpatialIndexBBFunc bbfunc, cpSpatialIndex* staticIndex);

alias cpSpatialIndexDestroyImpl = void function(cpSpatialIndex* index);

alias cpSpatialIndexCountImpl = int function(cpSpatialIndex* index);
alias cpSpatialIndexEachImpl = void function(cpSpatialIndex* index, cpSpatialIndexIteratorFunc func, void* data);

alias cpSpatialIndexContainsImpl = cpBool function(cpSpatialIndex* index, void* obj, cpHashValue hashid);
alias cpSpatialIndexInsertImpl = void function(cpSpatialIndex* index, void* obj, cpHashValue hashid);
alias cpSpatialIndexRemoveImpl = void function(cpSpatialIndex* index, void* obj, cpHashValue hashid);

alias cpSpatialIndexReindexImpl = void function(cpSpatialIndex* index);
alias cpSpatialIndexReindexObjectImpl = void function(cpSpatialIndex* index, void* obj, cpHashValue hashid);
alias cpSpatialIndexReindexQueryImpl = void function(cpSpatialIndex* index, cpSpatialIndexQueryFunc func, void* data);

alias cpSpatialIndexQueryImpl = void function(cpSpatialIndex* index, void* obj, cpBB bb, cpSpatialIndexQueryFunc func, void* data);
alias cpSpatialIndexSegmentQueryImpl = void function(cpSpatialIndex* index, void* obj, cpVect a, cpVect b, cpFloat t_exit, cpSpatialIndexSegmentQueryFunc func, void* data);

struct cpSpatialIndexClass
{
    cpSpatialIndexDestroyImpl destroy;

    cpSpatialIndexCountImpl count;
    cpSpatialIndexEachImpl each;

    cpSpatialIndexContainsImpl contains;
    cpSpatialIndexInsertImpl insert;
    cpSpatialIndexRemoveImpl remove;

    cpSpatialIndexReindexImpl reindex;
    cpSpatialIndexReindexObjectImpl reindexObject;
    cpSpatialIndexReindexQueryImpl reindexQuery;

    cpSpatialIndexQueryImpl query;
    cpSpatialIndexSegmentQueryImpl segmentQuery;
};

/// Destroy and free a spatial index.
void cpSpatialIndexFree(cpSpatialIndex* index)
{
    if (index)
    {
        cpSpatialIndexDestroy(index);
        cpfree(index);
    }
}

cpSpatialIndex* cpSpatialIndexInit(cpSpatialIndex* index, cpSpatialIndexClass* klass, cpSpatialIndexBBFunc bbfunc, cpSpatialIndex* staticIndex)
{
    index.klass       = klass;
    index.bbfunc      = bbfunc;
    index.staticIndex = staticIndex;

    if (staticIndex)
    {
        cpAssertHard(!staticIndex.dynamicIndex, "This static index is already associated with a dynamic index.");
        staticIndex.dynamicIndex = index;
    }

    return index;
}

struct dynamicToStaticContext
{
    cpSpatialIndexBBFunc bbfunc;
    cpSpatialIndex* staticIndex;
    cpSpatialIndexQueryFunc queryFunc;
    void* data;
}

void dynamicToStaticIter(void* obj, dynamicToStaticContext* context)
{
    cpSpatialIndexQuery(context.staticIndex, obj, context.bbfunc(obj), context.queryFunc, context.data);
}

void cpSpatialIndexCollideStatic(cpSpatialIndex* dynamicIndex, cpSpatialIndex* staticIndex, cpSpatialIndexQueryFunc func, void* data)
{
    if (staticIndex && cpSpatialIndexCount(staticIndex) > 0)
    {
        dynamicToStaticContext context = { dynamicIndex.bbfunc, staticIndex, func, data };
        cpSpatialIndexEach(dynamicIndex, cast(cpSpatialIndexIteratorFunc)&dynamicToStaticIter, &context);
    }
}

/// Collide the objects in @c dynamicIndex against the objects in @c staticIndex using the query callback function.
void cpSpatialIndexCollideStatic(cpSpatialIndex* dynamicIndex, cpSpatialIndex* staticIndex, cpSpatialIndexQueryFunc func, void* data);

/// Destroy a spatial index.
void cpSpatialIndexDestroy(cpSpatialIndex* index)
{
    if (index.klass)
        index.klass.destroy(index);
}

/// Get the number of objects in the spatial index.
int cpSpatialIndexCount(cpSpatialIndex* index)
{
    return index.klass.count(index);
}

/// Iterate the objects in the spatial index. @c func will be called once for each object.
void cpSpatialIndexEach(cpSpatialIndex* index, cpSpatialIndexIteratorFunc func, void* data)
{
    index.klass.each(index, func, data);
}

/// Returns true if the spatial index contains the given object.
/// Most spatial indexes use hashed storage, so you must provide a hash value too.
cpBool cpSpatialIndexContains(cpSpatialIndex* index, void* obj, cpHashValue hashid)
{
    return index.klass.contains(index, obj, hashid);
}

/// Add an object to a spatial index.
/// Most spatial indexes use hashed storage, so you must provide a hash value too.
void cpSpatialIndexInsert(cpSpatialIndex* index, void* obj, cpHashValue hashid)
{
    index.klass.insert(index, obj, hashid);
}

/// Remove an object from a spatial index.
/// Most spatial indexes use hashed storage, so you must provide a hash value too.
void cpSpatialIndexRemove(cpSpatialIndex* index, void* obj, cpHashValue hashid)
{
    index.klass.remove(index, obj, hashid);
}

/// Perform a full reindex of a spatial index.
void cpSpatialIndexReindex(cpSpatialIndex* index)
{
    index.klass.reindex(index);
}

/// Reindex a single object in the spatial index.
void cpSpatialIndexReindexObject(cpSpatialIndex* index, void* obj, cpHashValue hashid)
{
    index.klass.reindexObject(index, obj, hashid);
}

/// Perform a rectangle query against the spatial index, calling @c func for each potential match.
void cpSpatialIndexQuery(cpSpatialIndex* index, void* obj, cpBB bb, cpSpatialIndexQueryFunc func, void* data)
{
    index.klass.query(index, obj, bb, func, data);
}

/// Perform a segment query against the spatial index, calling @c func for each potential match.
void cpSpatialIndexSegmentQuery(cpSpatialIndex* index, void* obj, cpVect a, cpVect b, cpFloat t_exit, cpSpatialIndexSegmentQueryFunc func, void* data)
{
    index.klass.segmentQuery(index, obj, a, b, t_exit, func, data);
}

/// Simultaneously reindex and find all colliding objects.
/// @c func will be called once for each potentially overlapping pair of objects found.
/// If the spatial index was initialized with a static index, it will collide it's objects against that as well.
void cpSpatialIndexReindexQuery(cpSpatialIndex* index, cpSpatialIndexQueryFunc func, void* data)
{
    index.klass.reindexQuery(index, func, data);
}