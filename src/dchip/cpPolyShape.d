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
module dchip.cpPolyShape;

import dchip.cpBB;
import dchip.cpBody;
import dchip.chipmunk_types;
import dchip.cpShape;

/// @private
struct cpSplittingPlane
{
    cpVect n;
    cpFloat d;
}

/// @private
struct cpPolyShape
{
    cpShape shape;

    int numVerts;
    cpVect* verts;
    cpVect* tVerts;
    cpSplittingPlane* planes;
    cpSplittingPlane* tPlanes;

    cpFloat r;
}

/// Allocate a polygon shape.
cpPolyShape* cpPolyShapeAlloc();

/// Initialize a polygon shape.
/// A convex hull will be created from the vertexes.
cpPolyShape* cpPolyShapeInit(cpPolyShape* poly, cpBody* body_, int numVerts, const cpVect* verts, cpVect offset);

/// Initialize a polygon shape.
/// A convex hull will be created from the vertexes.
cpPolyShape* cpPolyShapeInit2(cpPolyShape* poly, cpBody* body_, int numVerts, const cpVect* verts, cpVect offset, cpFloat radius);

/// Allocate and initialize a polygon shape.
/// A convex hull will be created from the vertexes.
cpShape* cpPolyShapeNew(cpBody* body_, int numVerts, const cpVect* verts, cpVect offset);

/// Allocate and initialize a polygon shape.
/// A convex hull will be created from the vertexes.
cpShape* cpPolyShapeNew2(cpBody* body_, int numVerts, const cpVect* verts, cpVect offset, cpFloat radius);

/// Initialize a box shaped polygon shape.
cpPolyShape* cpBoxShapeInit(cpPolyShape* poly, cpBody* body_, cpFloat width, cpFloat height);

/// Initialize an offset box shaped polygon shape.
cpPolyShape* cpBoxShapeInit2(cpPolyShape* poly, cpBody* body_, cpBB box);

/// Initialize an offset box shaped polygon shape.
cpPolyShape* cpBoxShapeInit3(cpPolyShape* poly, cpBody* body_, cpBB box, cpFloat radius);

/// Allocate and initialize a box shaped polygon shape.
cpShape* cpBoxShapeNew(cpBody* body_, cpFloat width, cpFloat height);

/// Allocate and initialize an offset box shaped polygon shape.
cpShape* cpBoxShapeNew2(cpBody* body_, cpBB box);

/// Allocate and initialize an offset box shaped polygon shape.
cpShape* cpBoxShapeNew3(cpBody* body_, cpBB box, cpFloat radius);

/// Check that a set of vertexes is convex and has a clockwise winding.
/// NOTE: Due to floating point precision issues, hulls created with cpQuickHull() are not guaranteed to validate!
cpBool cpPolyValidate(const cpVect* verts, const int numVerts);

/// Get the number of verts in a polygon shape.
int cpPolyShapeGetNumVerts(const cpShape* shape);

/// Get the @c ith vertex of a polygon shape.
cpVect cpPolyShapeGetVert(const cpShape* shape, int idx);

/// Get the radius of a polygon shape.
cpFloat cpPolyShapeGetRadius(const cpShape* shape);
