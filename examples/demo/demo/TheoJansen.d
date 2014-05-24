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
module demo.TheoJansen;

import core.stdc.stdlib;

import std.math;

alias M_PI_2 = PI_2;

import demo.dchip;

import demo.ChipmunkDebugDraw;
import demo.ChipmunkDemo;
import demo.types;

/*
 * The previous WalkBot demo I designed was fairly disappointing, so I implemented
 * the mechanism that Theo Jansen uses in his kinetic sculptures. Brilliant.
 * Read more here: http://en.wikipedia.org/wiki/Theo_Jansen
 */

cpConstraint* motor;

void update(cpSpace* space, double dt)
{
    cpFloat coef = (2.0f + ChipmunkDemoKeyboard.y) / 3.0f;
    cpFloat rate = ChipmunkDemoKeyboard.x * 10.0f * coef;
    cpSimpleMotorSetRate(motor, rate);
    cpConstraintSetMaxForce(motor, (rate) ? 100000.0f : 0.0f);

    cpSpaceStep(space, dt);
}

cpFloat seg_radius = 3.0f;

void make_leg(cpSpace* space, cpFloat side, cpFloat offset, cpBody* chassis, cpBody* crank, cpVect anchor)
{
    cpVect a, b;
    cpShape* shape;

    cpFloat leg_mass = 1.0f;

    // make leg
    a = cpvzero, b = cpv(0.0f, side);
    cpBody* upper_leg = cpSpaceAddBody(space, cpBodyNew(leg_mass, cpMomentForSegment(leg_mass, a, b)));
    cpBodySetPos(upper_leg, cpv(offset, 0.0f));

    shape = cpSpaceAddShape(space, cpSegmentShapeNew(upper_leg, a, b, seg_radius));
    cpShapeSetGroup(shape, 1);

    cpSpaceAddConstraint(space, cpPivotJointNew2(chassis, upper_leg, cpv(offset, 0.0f), cpvzero));

    // lower leg
    a = cpvzero, b = cpv(0.0f, -1.0f * side);
    cpBody* lower_leg = cpSpaceAddBody(space, cpBodyNew(leg_mass, cpMomentForSegment(leg_mass, a, b)));
    cpBodySetPos(lower_leg, cpv(offset, -side));

    shape = cpSpaceAddShape(space, cpSegmentShapeNew(lower_leg, a, b, seg_radius));
    cpShapeSetGroup(shape, 1);

    shape = cpSpaceAddShape(space, cpCircleShapeNew(lower_leg, seg_radius * 2.0f, b));
    cpShapeSetGroup(shape, 1);
    cpShapeSetElasticity(shape, 0.0f);
    cpShapeSetFriction(shape, 1.0f);

    cpSpaceAddConstraint(space, cpPinJointNew(chassis, lower_leg, cpv(offset, 0.0f), cpvzero));

    cpSpaceAddConstraint(space, cpGearJointNew(upper_leg, lower_leg, 0.0f, 1.0f));

    cpConstraint* constraint;
    cpFloat diag = cpfsqrt(side * side + offset * offset);

    constraint = cpSpaceAddConstraint(space, cpPinJointNew(crank, upper_leg, anchor, cpv(0.0f, side)));
    cpPinJointSetDist(constraint, diag);

    constraint = cpSpaceAddConstraint(space, cpPinJointNew(crank, lower_leg, anchor, cpvzero));
    cpPinJointSetDist(constraint, diag);
}

cpSpace* init()
{
    ChipmunkDemoMessageString = "Use the arrow keys to control the machine.".dup;

    cpSpace* space = cpSpaceNew();
    cpSpaceSetIterations(space, 20);
    cpSpaceSetGravity(space, cpv(0, -500));

    cpBody * staticBody = cpSpaceGetStaticBody(space);
    cpShape* shape;
    cpVect a, b;

    // Create segments around the edge of the screen.
    shape = cpSpaceAddShape(space, cpSegmentShapeNew(staticBody, cpv(-320, -240), cpv(-320, 240), 0.0f));
    cpShapeSetElasticity(shape, 1.0f);
    cpShapeSetFriction(shape, 1.0f);
    cpShapeSetLayers(shape, NOT_GRABABLE_MASK);

    shape = cpSpaceAddShape(space, cpSegmentShapeNew(staticBody, cpv(320, -240), cpv(320, 240), 0.0f));
    cpShapeSetElasticity(shape, 1.0f);
    cpShapeSetFriction(shape, 1.0f);
    cpShapeSetLayers(shape, NOT_GRABABLE_MASK);

    shape = cpSpaceAddShape(space, cpSegmentShapeNew(staticBody, cpv(-320, -240), cpv(320, -240), 0.0f));
    cpShapeSetElasticity(shape, 1.0f);
    cpShapeSetFriction(shape, 1.0f);
    cpShapeSetLayers(shape, NOT_GRABABLE_MASK);

    cpFloat offset = 30.0f;

    // make chassis
    cpFloat chassis_mass = 2.0f;
    a = cpv(-offset, 0.0f), b = cpv(offset, 0.0f);
    cpBody* chassis = cpSpaceAddBody(space, cpBodyNew(chassis_mass, cpMomentForSegment(chassis_mass, a, b)));

    shape = cpSpaceAddShape(space, cpSegmentShapeNew(chassis, a, b, seg_radius));
    cpShapeSetGroup(shape, 1);

    // make crank
    cpFloat crank_mass   = 1.0f;
    cpFloat crank_radius = 13.0f;
    cpBody* crank        = cpSpaceAddBody(space, cpBodyNew(crank_mass, cpMomentForCircle(crank_mass, crank_radius, 0.0f, cpvzero)));

    shape = cpSpaceAddShape(space, cpCircleShapeNew(crank, crank_radius, cpvzero));
    cpShapeSetGroup(shape, 1);

    cpSpaceAddConstraint(space, cpPivotJointNew2(chassis, crank, cpvzero, cpvzero));

    cpFloat side = 30.0f;

    int num_legs = 2;

    for (int i = 0; i < num_legs; i++)
    {
        make_leg(space, side, offset, chassis, crank, cpvmult(cpvforangle(cast(cpFloat)(2 * i + 0) / cast(cpFloat)num_legs * M_PI), crank_radius));
        make_leg(space, side, -offset, chassis, crank, cpvmult(cpvforangle(cast(cpFloat)(2 * i + 1) / cast(cpFloat)num_legs * M_PI), crank_radius));
    }

    motor = cpSpaceAddConstraint(space, cpSimpleMotorNew(chassis, crank, 6.0f));

    return space;
}

void destroy(cpSpace* space)
{
    ChipmunkDemoFreeSpaceChildren(space);
    cpSpaceFree(space);
}

ChipmunkDemo TheoJansen = {
    "Theo Jansen Machine",
    1.0 / 180.0,
    &init,
    &update,
    &ChipmunkDemoDefaultDrawImpl,
    &destroy,
};