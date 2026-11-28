# Character, Rigging and Motion Direction

## Character bible
Assign stable IDs such as CHAR_01. Record silhouette, relative height, body proportions, face layout, palette, costume, materials, personality, posture, gait, gesture vocabulary, voice ID, language, rig type and facial controls. Keep identity and proportions consistent across scenes.

## Rig choices
- Stickman: root, pelvis, chest, neck/head, shoulders, elbows, wrists, hips, knees and ankles.
- 2D cut-out: layered parts with named pivots and parent-child limb chains.
- 3D biped: root, pelvis, spine, neck, head, clavicles, arms, hands, legs and feet.
- Quadruped: spine chain, shoulder/hip groups, four limb chains, tail and head controls.
- Robot: rigid parented parts, hinge limits and explicit contact points.

Use forward kinematics for predictable posing. Use inverse kinematics when feet or hands must reach a target or remain planted. Define clear FK/IK switching rules.

## The 12 animation principles
1. Squash and stretch — preserve volume unless stylization requires otherwise.
2. Anticipation — prepare the audience for the action.
3. Staging — make the focal action unmistakable.
4. Straight-ahead / pose-to-pose — choose according to continuity needs.
5. Follow-through and overlap — secondary parts settle after the main body.
6. Slow in / slow out — avoid mechanical linear motion unless intended.
7. Arcs — keep hands, head and body paths readable.
8. Secondary action — support, never distract from, the main action.
9. Timing — specify frames and beats.
10. Exaggeration — amplify the important read without breaking the character.
11. Solid volume — preserve anatomy, perspective and shape.
12. Appeal — clear design, readable posing and intentional rhythm.

## Contact and locomotion
- Mark foot-plant intervals and prevent foot sliding.
- Shift center of mass over the support foot before lifting the other foot.
- Punch: wind-up, acceleration, contact, recoil, recovery.
- Jump: crouch, takeoff, apex, landing compression, settle.
- Fall: loss of balance, impact, secondary collision, recovery.
- Dance: beat grid, weight transfer, repeated motif, variation.

## Physics and procedural motion
Use deterministic keyframes as the source of truth. Add gravity, collision, ragdoll, cloth or particles only when useful. Use a fixed timestep, clamp unstable simulation and seed randomness for repeatable renders.

## Facial acting and lip sync
Track eye target, blinks, brows, head motion and mouth shapes independently. Align visemes to final audio when phoneme timing is available; otherwise use timed mouth-shape groups and expressive holds.

## Quality gate
Review silhouette, joint bending, foot sliding, penetration, popping, scale drift, clipping and pose continuity. Fix key poses before polishing in-betweens.
