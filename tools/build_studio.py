#!/usr/bin/env python3
"""Builds Content/Studio/movements.json and sessions.json from the tables below,
checks every reference, and prints each session's real length.

All movement names are common public exercise and pose names. All cues,
selections, orders and timings are original to Rep Bell."""
import json
import pathlib
import sys

OUT = pathlib.Path(__file__).resolve().parent.parent / "Content" / "Studio"

# id, name, setup cue, fault cue, sides, gear, stand-in, easier, harder, view, keyframes
M = [
    # Warm-up and cool-down
    ("march", "March in place", "Stand tall and lift each knee to hip height.", "Swing the opposite arm; don't lean back.", "alternating", [], None, None, "high-knees", "front", ["knee up left", "knee up right"]),
    ("arm-circles", "Arm circles", "Arms straight out to the sides, palms down.", "Small circles first, then bigger. Shoulders stay low.", "none", [], None, None, None, "front", ["arms out", "arms circling"]),
    ("hip-circles", "Hip circles", "Hands on hips, feet hip-width apart.", "Draw a slow circle with your hips; keep your head still.", "none", [], None, None, None, "front", ["hips left", "hips right"]),
    ("good-morning", "Bodyweight good morning", "Hands behind your head, soft knees.", "Hinge at the hips with a flat back until you feel your hamstrings.", "none", [], None, None, None, "side", ["standing", "hinged"]),
    ("inchworm", "Inchworm walk-out", "Fold forward and put your hands on the floor.", "Walk your hands out to a plank, then walk them back. Keep the legs as straight as you can.", "none", ["mat"], None, None, None, "side", ["fold", "plank"]),
    ("childs-pose", "Child's pose", "Knees wide, big toes together, sit back on your heels.", "Reach your arms forward and let your forehead rest down.", "none", ["mat"], None, None, None, "side", ["resting"]),
    ("wall-chest", "Chest opener at a wall", "Forearm on a wall at shoulder height.", "Turn your body away slowly until you feel the front of your shoulder.", "each", [], "doorframe", None, None, "side", ["arm on wall", "turned away"]),
    ("hamstring-fold", "Standing hamstring fold", "Feet hip-width, knees soft.", "Fold from the hips and let your head hang. Don't bounce.", "none", [], None, None, None, "side", ["folded"]),
    ("breathing", "Slow breathing", "Stand or sit tall, hands on your belly.", "In for four, out for six. Let your shoulders drop.", "none", [], None, None, None, "front", ["breath in", "breath out"]),

    # Upper
    ("push-up", "Standard push-up", "Hands just wider than shoulders, body in one straight line.", "Lower until your chest is a fist from the floor. Don't let your hips sag.", "none", [], None, "knee-push-up", "decline-push-up", "side", ["top", "bottom"]),
    ("knee-push-up", "Knee push-up", "Knees down, hands under shoulders, hips in line with your back.", "Lower your chest, not your face.", "none", ["mat"], None, "incline-push-up", "push-up", "side", ["top", "bottom"]),
    ("incline-push-up", "Incline push-up", "Hands on a counter or sturdy chair, body straight.", "The higher the surface, the easier it gets.", "none", ["chair"], "counter", None, "knee-push-up", "side", ["top", "bottom"]),
    ("wide-push-up", "Wide push-up", "Hands a hand's width wider than a normal push-up.", "Elbows point out at about 45 degrees, not straight sideways.", "none", [], None, "knee-push-up", None, "front", ["top", "bottom"]),
    ("decline-push-up", "Decline push-up", "Feet up on a chair or step, hands on the floor.", "Keep your core tight so your lower back doesn't arch.", "none", ["chair"], "step", "push-up", None, "side", ["top", "bottom"]),
    ("diamond-push-up", "Close-grip push-up", "Hands under your chest, thumbs and fingers nearly touching.", "Elbows brush your ribs on the way down.", "none", [], None, "knee-push-up", None, "front", ["top", "bottom"]),
    ("band-row", "Band row", "Anchor the band at chest height, step back until it's tight.", "Pull your elbows back and squeeze your shoulder blades. Don't shrug.", "none", ["band"], "towel-row", None, "pull-up", "side", ["arms long", "elbows back"]),
    ("towel-row", "Towel door row", "Loop a towel around a closed door's handles, lean back holding both ends.", "Pull your chest to the door. Check the door is shut and latched first.", "none", [], None, None, "table-row", "side", ["leaning back", "pulled in"]),
    ("underhand-band-row", "Underhand band row", "Same as a band row, palms up.", "Lead with your elbows; finish with a squeeze.", "none", ["band"], "towel-row", None, "chin-up", "side", ["arms long", "elbows back"]),
    ("pull-up", "Pull-up", "Hang from the bar, hands just wider than shoulders, palms away.", "Pull your chest toward the bar, then lower all the way. No swinging.", "none", ["bar"], "band-row", "negative-pull-up", None, "front", ["hang", "chin over bar"]),
    ("negative-pull-up", "Slow lowering pull-up", "Jump or step up so your chin is over the bar.", "Lower yourself over five slow seconds.", "none", ["bar", "chair"], "band-row", "band-row", "pull-up", "front", ["chin over bar", "hang"]),
    ("chin-up", "Chin-up", "Hang from the bar, palms facing you, shoulder-width.", "Lead with your chest. Lower under control.", "none", ["bar"], "underhand-band-row", "negative-pull-up", None, "front", ["hang", "chin over bar"]),
    ("table-row", "Table row", "Lie under a sturdy table, grip the edge, heels on the floor.", "Pull your chest to the table and keep your hips up.", "none", ["table"], "towel-row", "bent-knee-table-row", None, "side", ["arms long", "chest up"]),
    ("bent-knee-table-row", "Bent-knee table row", "Same as a table row with your knees bent and feet flat.", "Drive through your heels to keep your hips level.", "none", ["table"], "towel-row", None, "table-row", "side", ["arms long", "chest up"]),

    # Lower and back
    ("squat", "Bodyweight squat", "Feet shoulder-width, toes slightly out.", "Sit back and down; knees track over your toes, heels stay down.", "none", [], None, "chair-squat", "squat-jump", "side", ["standing", "bottom"]),
    ("chair-squat", "Squat to chair", "Stand in front of a chair, arms forward.", "Tap the chair with your hips and stand back up without rocking.", "none", ["chair"], None, None, "squat", "side", ["standing", "seated tap"]),
    ("reverse-lunge", "Reverse lunge", "Stand tall, step one foot back.", "Lower until both knees are near 90 degrees. Front knee stays over the ankle.", "alternating", [], None, "static-lunge", "split-jump", "side", ["standing", "bottom"]),
    ("static-lunge", "Split stance hold-and-dip", "Take a long split stance and hold onto a chair if you need to.", "Small dips straight down. Keep your torso upright.", "each", [], "chair", None, "reverse-lunge", "side", ["top", "bottom"]),
    ("glute-bridge", "Glute bridge", "On your back, knees bent, feet flat and close to your hips.", "Push through your heels and lift your hips. Squeeze at the top, don't arch your back.", "none", ["mat"], None, None, "bridge-march", "side", ["down", "up"]),
    ("split-squat", "Rear-foot split squat", "Back foot on a chair, front foot a big step forward.", "Drop the back knee straight down. Most of your weight stays on the front leg.", "each", ["chair"], None, "static-lunge", None, "side", ["top", "bottom"]),
    ("superman", "Superman hold", "Lie face down, arms reaching forward.", "Lift your arms, chest and legs a few inches. Look at the floor, not ahead.", "none", ["mat"], None, "bird-dog", None, "side", ["down", "lifted"]),
    ("wall-sit", "Wall sit", "Back flat on a wall, slide down until your knees are near 90 degrees.", "Knees over ankles. Breathe; don't hold your breath.", "none", [], None, None, None, "side", ["seated on wall"]),
    ("calf-raise", "Calf raise", "Stand tall, hold a wall for balance.", "Rise onto the balls of your feet, pause, lower slowly.", "none", [], None, None, None, "side", ["down", "up"]),

    # Shoulders and arms
    ("pike-push-up", "Pike push-up", "Hips high in an upside-down V, hands shoulder-width.", "Lower the top of your head toward the floor between your hands.", "none", ["mat"], None, "incline-push-up", None, "side", ["top", "bottom"]),
    ("lateral-raise", "Lateral raise", "Stand on the band or hold weights at your sides.", "Lift your arms out to shoulder height with soft elbows. No swinging.", "none", ["band"], "water-jugs", None, None, "front", ["arms down", "arms out"]),
    ("curl", "Curl", "Stand on the band or hold weights, palms forward.", "Elbows stay pinned at your sides. Lower slowly.", "none", ["band"], "water-jugs", None, None, "front", ["down", "up"]),
    ("chair-dip", "Chair dip", "Hands on the edge of a sturdy chair, legs out in front.", "Bend your elbows straight back, not out. Shoulders stay away from your ears.", "none", ["chair"], None, "bent-knee-dip", None, "side", ["top", "bottom"]),
    ("bent-knee-dip", "Bent-knee chair dip", "Same as a chair dip with knees bent and feet close.", "Use your legs as little as you can.", "none", ["chair"], None, None, "chair-dip", "side", ["top", "bottom"]),
    ("overhead-press", "Overhead press", "Stand on the band or hold weights at your shoulders.", "Press straight up without arching your back. Ribs stay down.", "none", ["band"], "water-jugs", None, "pike-push-up", "front", ["at shoulders", "overhead"]),
    ("hammer-curl", "Hammer curl", "Hold the band or weights with palms facing each other.", "Same as a curl, thumbs up the whole time.", "none", ["band"], "water-jugs", None, None, "front", ["down", "up"]),
    ("triceps-extension", "Overhead triceps extension", "Hold one end of the band or one weight with both hands overhead.", "Lower it behind your head by bending only at the elbows.", "none", ["band"], "water-jugs", None, None, "side", ["overhead", "behind head"]),
    ("shoulder-tap", "Plank shoulder tap", "High plank, feet a little wider than hips.", "Tap the opposite shoulder without rocking your hips.", "alternating", [], None, "knee-plank", None, "front", ["plank", "tap"]),

    # Jump and low-impact swaps
    ("squat-jump", "Squat jump", "Squat down with your arms back.", "Jump straight up and land softly back into the squat.", "none", [], None, "squat-calf-raise", None, "side", ["bottom", "air"]),
    ("squat-calf-raise", "Squat to calf raise", "Squat down, then stand and rise onto your toes.", "Same rhythm as a jump with no landing.", "none", [], None, None, "squat-jump", "side", ["bottom", "on toes"]),
    ("skater-hop", "Skater hop", "Hop sideways from one foot to the other.", "Land softly on the outside leg, back foot sweeps behind.", "alternating", [], None, "skater-step", None, "front", ["land left", "land right"]),
    ("skater-step", "Skater step", "Step wide to one side and sweep the other foot behind.", "Stay low and keep it smooth.", "alternating", [], None, None, "skater-hop", "front", ["step left", "step right"]),
    ("high-knees", "High knees", "Run in place, driving your knees up.", "Stay on the balls of your feet and pump your arms.", "alternating", [], None, "march", None, "side", ["knee left", "knee right"]),
    ("lateral-shuffle", "Lateral shuffle", "Athletic stance, knees bent.", "Shuffle three steps one way, three back. Feet never cross.", "none", [], None, "side-step", None, "front", ["wide", "narrow"]),
    ("side-step", "Side step", "Step side to side with soft knees.", "Reach your arms out as you step for a bit more work.", "none", [], None, None, "lateral-shuffle", "front", ["step left", "step right"]),
    ("split-jump", "Split jump", "Start in a lunge.", "Jump and switch legs in the air. Land softly with both knees bent.", "alternating", [], None, "reverse-lunge", None, "side", ["lunge left", "lunge right"]),
    ("burpee", "Burpee, no push-up", "Squat, hands down, jump your feet back to a plank.", "Jump your feet in, stand and reach up. Keep your hips level in the plank.", "none", [], None, "step-back-burpee", None, "side", ["squat", "plank", "reach"]),
    ("step-back-burpee", "Step-back burpee", "Hands down, step one foot back at a time to a plank.", "Step back in and stand tall. No jumping.", "none", [], None, None, "burpee", "side", ["squat", "plank", "stand"]),

    # Flow
    ("cat-cow", "Cat-cow", "Hands under shoulders, knees under hips.", "Breathe in as your belly drops and chest lifts; breathe out as you round your back.", "none", ["mat"], None, None, None, "side", ["cow", "cat"]),
    ("downward-dog", "Downward dog", "From hands and knees, lift your hips up and back.", "Press the floor away. Bend your knees if your back rounds.", "none", ["mat"], None, None, None, "side", ["v shape"]),
    ("low-lunge", "Low lunge", "One foot forward between your hands, back knee down.", "Sink your hips forward and lift your chest.", "each", ["mat"], None, None, None, "side", ["low lunge"]),
    ("warrior-one", "Warrior one", "Front knee bent over the ankle, back heel down, hips facing forward.", "Reach your arms overhead without arching your lower back.", "each", ["mat"], None, None, None, "side", ["warrior one"]),
    ("warrior-two", "Warrior two", "Wide stance, front knee bent, hips open to the side.", "Arms reach long both ways; your gaze goes over the front hand.", "each", ["mat"], None, None, None, "front", ["warrior two"]),
    ("reverse-warrior", "Reverse warrior", "From warrior two, flip your front palm up.", "Reach up and back while the front knee stays bent.", "each", ["mat"], None, None, None, "front", ["reverse warrior"]),
    ("triangle", "Triangle", "Wide stance with straight legs, front toes forward.", "Reach forward, then tip down to your shin or a block. Don't collapse your side.", "each", ["mat", "block"], "book", None, None, "front", ["triangle"]),
    ("side-angle", "Side angle", "From warrior two, rest your forearm on your front thigh.", "Reach the top arm over your ear in one long line.", "each", ["mat"], None, None, None, "front", ["side angle"]),
    ("chair-pose", "Chair pose", "Feet together, sit back as if into a chair.", "Arms up, weight in your heels, knees behind your toes.", "none", ["mat"], None, None, None, "side", ["chair"]),
    ("tree", "Tree", "Stand on one leg, sole of the other foot on your calf or thigh.", "Never press the foot into the knee. Hands at your chest or overhead.", "each", ["mat"], None, None, None, "front", ["tree"]),
    ("half-moon", "Half moon", "From triangle, bend the front knee and put a hand on a block ahead.", "Lift the back leg level with your hip and open your chest to the side.", "each", ["mat", "block"], "book", "triangle", None, "front", ["half moon"]),
    ("bridge-pose", "Bridge", "On your back, feet flat, arms by your sides.", "Lift your hips and roll your shoulders under. Keep your knees in line with your feet.", "none", ["mat"], None, None, None, "side", ["bridge"]),
    ("seated-fold", "Seated forward fold", "Sit with legs straight out, knees soft.", "Lengthen your spine first, then fold from the hips.", "none", ["mat"], None, None, None, "side", ["folded"]),
    ("figure-four", "Figure-four stretch", "On your back, cross one ankle over the opposite knee.", "Pull the bottom leg toward you until you feel the outer hip.", "each", ["mat"], None, None, None, "side", ["figure four"]),
    ("supine-twist", "Supine twist", "On your back, hug one knee in, then let it fall across your body.", "Both shoulders stay on the floor.", "each", ["mat"], None, None, None, "front", ["twist"]),
    ("final-rest", "Final rest", "Lie on your back, arms by your sides, palms up.", "Let everything go heavy. Stay still.", "none", ["mat"], None, None, None, "front", ["lying"]),

    # Strike
    ("fighting-stance", "Fighting stance", "Feet staggered, hands up by your cheeks, chin down.", "Bounce lightly on the balls of your feet.", "none", [], None, None, None, "front", ["stance"]),
    ("jab", "Jab", "Punch straight out with your lead hand and snap it back.", "Exhale on every punch; the other hand stays guarding your face.", "none", [], None, None, None, "front", ["guard", "jab"]),
    ("jab-cross", "Jab-cross", "Jab, then punch straight with your rear hand.", "Pivot the rear foot and turn your hips on the cross.", "none", [], None, "jab", None, "front", ["jab", "cross"]),
    ("hook", "Hook", "Bend your elbow to 90 degrees and swing it level across.", "Power comes from turning your hips and lead foot, not the arm.", "alternating", [], None, None, None, "front", ["guard", "hook"]),
    ("uppercut", "Uppercut", "Dip your knees slightly and drive your fist up.", "Keep the punch close to your body.", "alternating", [], None, None, None, "front", ["dip", "uppercut"]),
    ("front-kick", "Front kick", "Lift your knee, then push your foot straight out.", "Pull the foot back before you set it down. Hands stay up.", "alternating", [], None, "knee-strike", None, "side", ["knee up", "kick"]),
    ("knee-strike", "Knee strike", "Grab an imaginary target at chest height.", "Drive your knee up and pull your hands down to meet it.", "alternating", [], None, None, "front-kick", "side", ["reach", "knee up"]),
    ("side-kick", "Side kick", "Turn sideways, lift your knee across your body.", "Push your heel out to the side; lean your torso away for balance.", "alternating", [], None, "knee-strike", None, "front", ["chamber", "kick"]),
    ("bounce", "Light bounce", "Fighting stance, hands up.", "Small, easy bounces to recover between combos.", "none", [], None, None, None, "front", ["bounce up", "bounce down"]),

    # Core
    ("forearm-plank", "Forearm plank", "Elbows under shoulders, body in one straight line.", "Squeeze your glutes and pull your belly button in. Don't let your hips sag.", "none", ["mat"], None, "knee-plank", "shoulder-tap", "side", ["plank"]),
    ("knee-plank", "Knee plank", "Forearms down, knees down, hips in line with your back.", "Same tight core as a full plank.", "none", ["mat"], None, None, "forearm-plank", "side", ["plank"]),
    ("dead-bug", "Dead bug", "On your back, arms up, knees bent over your hips.", "Lower the opposite arm and leg slowly. Keep your lower back on the floor.", "alternating", ["mat"], None, None, None, "side", ["start", "reach"]),
    ("side-plank", "Side plank", "On one forearm, feet stacked, body in a straight line.", "Lift your hips; don't let them drop toward the floor.", "each", ["mat"], None, "knee-side-plank", None, "front", ["side plank"]),
    ("knee-side-plank", "Knee side plank", "Same as a side plank with your knees bent and down.", "Hips forward, in line with your shoulders.", "each", ["mat"], None, None, "side-plank", "front", ["side plank"]),
    ("bird-dog", "Bird dog", "Hands and knees, back flat.", "Reach the opposite arm and leg long. Keep your hips level as if balancing a cup on your back.", "alternating", ["mat"], None, None, "superman", "side", ["start", "reach"]),
    ("hollow-hold", "Hollow hold", "On your back, press your lower back down, lift shoulders and legs.", "Bend your knees to make it easier. Your lower back never lifts.", "none", ["mat"], None, "dead-bug", None, "side", ["hollow"]),
    ("mountain-climber", "Mountain climber", "High plank, hands under shoulders.", "Drive your knees toward your chest one at a time. Hips stay low.", "alternating", [], None, "slow-climber", None, "side", ["knee left", "knee right"]),
    ("slow-climber", "Slow mountain climber", "High plank, step one knee in at a time.", "Pause each step and keep your shoulders over your hands.", "alternating", [], None, None, "mountain-climber", "side", ["knee left", "knee right"]),
    ("bridge-march", "Glute bridge march", "Hold a glute bridge at the top.", "Lift one foot at a time without your hips dropping.", "alternating", ["mat"], None, "glute-bridge", None, "side", ["bridge left", "bridge right"]),
    ("russian-twist", "Russian twist", "Sit leaning back slightly, knees bent, heels down.", "Turn your chest side to side, not just your arms.", "alternating", ["mat"], None, None, None, "front", ["twist left", "twist right"]),

    # Abs
    ("crunch", "Crunch", "On your back, knees bent, fingertips behind your ears.", "Curl your shoulders up with your belly. Don't pull on your neck.", "none", ["mat"], None, None, None, "side", ["down", "up"]),
    ("bicycle", "Bicycle", "On your back, hands behind your head, legs lifted.", "Bring the opposite elbow toward the knee as the other leg reaches long. Slow beats fast.", "alternating", ["mat"], None, "crunch", None, "front", ["twist left", "twist right"]),
    ("reverse-crunch", "Reverse crunch", "On your back, knees bent at 90 degrees above your hips.", "Curl your hips off the floor toward your chest, then lower slowly.", "none", ["mat"], None, None, None, "side", ["down", "curled"]),
    ("leg-raise", "Straight-leg raise", "On your back, legs straight, hands under your hips.", "Lower your legs only as far as your lower back stays down.", "none", ["mat"], None, "reverse-crunch", None, "side", ["legs up", "legs low"]),
    ("flutter-kick", "Flutter kick", "On your back, legs straight and a few inches up.", "Small quick kicks. Press your lower back into the floor.", "alternating", ["mat"], None, "dead-bug", None, "side", ["kick left", "kick right"]),

    # Easy cardio
    ("step-jack", "Step jack", "Step one foot out to the side as your arms go overhead.", "Step back in and switch sides. No jumping.", "alternating", [], None, None, None, "front", ["out", "in"]),
    ("shadow-boxing", "Shadow boxing", "Fighting stance, hands up.", "Easy jabs and crosses while you move your feet.", "none", [], None, None, None, "front", ["jab", "cross"]),
    ("butt-kick", "Butt kick", "Jog in place, heels toward your glutes.", "Stay tall and light on your feet.", "alternating", [], None, "march", None, "side", ["heel left", "heel right"]),
    ("march-reach", "March with arm reach", "March in place, reaching one arm up as the opposite knee lifts.", "Keep a steady rhythm.", "alternating", [], None, "march", None, "front", ["reach left", "reach right"]),
    ("knee-drive", "Standing knee drive", "Stagger your feet, arms reaching up.", "Pull your arms down as your back knee drives up. Switch halfway.", "each", [], None, "march", None, "side", ["reach", "knee up"]),
    ("easy-walk", "Easy walk", "Walk in place or around the room.", "Let your breathing settle.", "none", [], None, None, None, "front", ["step left", "step right"]),

    # Stretch
    ("neck-stretch", "Neck side stretch", "Sit or stand tall, tip your ear toward your shoulder.", "Let the opposite shoulder drop. No pulling on your head.", "each", [], None, None, None, "front", ["tipped"]),
    ("doorway-chest", "Doorway chest stretch", "Forearms on a doorframe, elbows at shoulder height.", "Step one foot through until you feel the chest open.", "none", [], "wall", None, None, "side", ["stretching"]),
    ("cross-shoulder", "Cross-body shoulder stretch", "Bring one arm across your chest.", "Hold it above the elbow with the other hand. Shoulder stays down.", "each", [], None, None, None, "front", ["stretching"]),
    ("hip-flexor", "Kneeling hip flexor stretch", "Kneel on one knee, other foot forward.", "Squeeze the glute of the back leg and shift your hips forward.", "each", ["mat"], None, None, None, "side", ["stretching"]),
    ("seated-hamstring", "Seated hamstring stretch", "Sit with one leg straight, the other foot against the inner thigh.", "Fold toward the straight leg with a long back.", "each", ["mat"], None, None, None, "side", ["stretching"]),
    ("quad-stretch", "Standing quad stretch", "Hold a wall, grab one ankle behind you.", "Knees side by side, hips pressed forward.", "each", [], None, None, None, "side", ["stretching"]),
    ("calf-wall", "Calf stretch at a wall", "Hands on a wall, one foot back, heel down.", "Lean in with the back leg straight.", "each", [], None, None, None, "side", ["stretching"]),
]

WARMUP = [("march", 45), ("arm-circles", 60), ("hip-circles", 30), ("good-morning", 45), ("inchworm", 60)]
COOLDOWN = [("childs-pose", 45), ("wall-chest", 60), ("hamstring-fold", 45), ("breathing", 30)]


def circuit(rounds, work, rest, between, moves):
    return {"kind": "circuit", "rounds": rounds, "work": work, "rest": rest, "restBetweenRounds": between, "moves": moves}


def sequence(moves, rest=0):
    """moves: list of (id, seconds). 'each' moves get the time per side."""
    return {"kind": "sequence", "rest": rest, "moves": [{"id": m, "seconds": s} for m, s in moves]}


S = [
    dict(id="upper", name="Upper", gear=["bar", "band"], free=False, warmup=True, cooldown=True,
         blocks=[circuit(4, 45, 15, 90, ["push-up", "band-row", "wide-push-up", "underhand-band-row", "decline-push-up", "table-row", "diamond-push-up", "towel-row"])]),
    dict(id="lower-back", name="Lower and back", gear=["chair"], free=False, warmup=True, cooldown=True,
         blocks=[circuit(4, 45, 15, 90, ["squat", "reverse-lunge", "glute-bridge", "split-squat", "superman", "wall-sit", "calf-raise", "good-morning"])]),
    dict(id="shoulders-arms", name="Shoulders and arms", gear=["band", "chair"], free=False, warmup=True, cooldown=True,
         blocks=[circuit(3, 45, 15, 90, ["pike-push-up", "lateral-raise", "curl", "chair-dip", "overhead-press", "hammer-curl", "triceps-extension", "shoulder-tap"])]),
    dict(id="jump", name="Jump", gear=[], free=False, warmup=True, cooldown=True,
         blocks=[circuit(4, 30, 30, 60, ["squat-jump", "skater-hop", "high-knees", "lateral-shuffle", "split-jump", "burpee"])]),
    dict(id="flow", name="Flow", gear=["mat", "block"], free=False, warmup=False, cooldown=False,
         blocks=[sequence([("breathing", 60), ("cat-cow", 90), ("downward-dog", 60), ("low-lunge", 60), ("downward-dog", 45),
                           ("warrior-one", 60), ("warrior-two", 60), ("reverse-warrior", 45), ("triangle", 60), ("side-angle", 45),
                           ("downward-dog", 45), ("chair-pose", 45), ("tree", 60), ("half-moon", 45), ("childs-pose", 60),
                           ("bridge-pose", 60), ("seated-fold", 90), ("figure-four", 75), ("supine-twist", 60),
                           ("final-rest", 240)], rest=10)]),
    dict(id="strike", name="Strike", gear=[], free=False, warmup=True, cooldown=True,
         blocks=[circuit(6, 20, 0, 30, ["fighting-stance", "jab", "jab-cross", "hook", "uppercut", "front-kick", "knee-strike", "side-kick", "bounce"])]),
    dict(id="core", name="Core", gear=["mat"], free=False, warmup=True, cooldown=True,
         blocks=[circuit(3, 40, 20, 60, ["forearm-plank", "dead-bug", "side-plank", "bird-dog", "hollow-hold", "mountain-climber", "bridge-march", "russian-twist"])]),
    dict(id="ab-finisher", name="Ab finisher", gear=["mat"], free=True, warmup=False, cooldown=False,
         blocks=[circuit(2, 40, 10, 30, ["crunch", "bicycle", "reverse-crunch", "leg-raise", "flutter-kick", "forearm-plank"])]),
    dict(id="easy-cardio", name="Easy cardio", gear=[], free=False, warmup=True, cooldown=True,
         blocks=[dict(circuit(3, 60, 0, 60, ["step-jack", "shadow-boxing", "lateral-shuffle", "butt-kick", "march-reach", "knee-drive"]), betweenRoundsMove="easy-walk")]),
    dict(id="stretch", name="Stretch", gear=["mat"], free=True, warmup=False, cooldown=False,
         blocks=[sequence([("breathing", 45), ("neck-stretch", 60), ("doorway-chest", 45), ("cross-shoulder", 60), ("hip-flexor", 90),
                           ("seated-hamstring", 90), ("quad-stretch", 60), ("calf-wall", 60), ("figure-four", 90),
                           ("childs-pose", 60), ("supine-twist", 90), ("final-rest", 90)], rest=5)]),
]

SUGGEST = {
    "testDay": ["flow", "stretch"],
    "dayAfterTest": ["stretch", "flow"],
    "pushDay": ["lower-back", "core", "easy-cardio", "ab-finisher"],
    "never_on_pushDay": ["upper", "shoulders-arms"],
}


def main():
    movements = []
    ids = set()
    for row in M:
        mid, name, setup, fault, sides, gear, stand, easier, harder, view, keys = row
        if mid in ids:
            sys.exit(f"duplicate id {mid}")
        ids.add(mid)
        movements.append({"id": mid, "name": name, "cues": [setup, fault], "sides": sides, "gear": gear,
                          "standIn": stand, "easier": easier, "harder": harder, "view": view, "keyframes": keys})
    by_id = {m["id"]: m for m in movements}
    errors = []
    for m in movements:
        for ref in ("easier", "harder"):
            if m[ref] and m[ref] not in ids:
                errors.append(f"{m['id']}.{ref} -> {m[ref]} missing")
        if m["standIn"] and m["standIn"] in ids and m["standIn"] == m["id"]:
            errors.append(f"{m['id']} stands in for itself")
    used = set()

    def secs_seq(moves):
        t = 0
        for mid, s in moves:
            if mid not in ids:
                errors.append(f"missing {mid}")
                continue
            used.add(mid)
            t += s * (2 if by_id[mid]["sides"] == "each" else 1)
        return t

    sessions = []
    print(f"{'session':<20}{'min':>5}  moves")
    for s in S:
        total = 0
        if s["warmup"]:
            total += secs_seq(WARMUP)
        for b in s["blocks"]:
            if b["kind"] == "circuit":
                if b.get("betweenRoundsMove"):
                    used.add(b["betweenRoundsMove"])
                for mid in b["moves"]:
                    if mid not in ids:
                        errors.append(f"{s['id']}: missing {mid}")
                    used.add(mid)
                n = len(b["moves"])
                total += b["rounds"] * n * (b["work"] + b["rest"]) + (b["rounds"] - 1) * b["restBetweenRounds"]
            else:
                total += secs_seq([(m["id"], m["seconds"]) for m in b["moves"]])
                total += b["rest"] * (len(b["moves"]) - 1)
        if s["cooldown"]:
            total += secs_seq(COOLDOWN)
        s = dict(s, minutes=round(total / 60))
        sessions.append(s)
        count = sum(len(b["moves"]) for b in s["blocks"])
        print(f"{s['name']:<20}{s['minutes']:>5}  {count}")
    for m in movements:
        for ref in ("easier", "harder"):
            if m[ref]:
                used.add(m[ref])
    unused = sorted(ids - used)
    if errors:
        sys.exit("\n".join(errors))
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "movements.json").write_text(json.dumps({"version": 1, "movements": movements}, indent=2) + "\n")
    (OUT / "sessions.json").write_text(json.dumps({"version": 1, "warmup": [{"id": m, "seconds": s} for m, s in WARMUP],
                                                   "cooldown": [{"id": m, "seconds": s} for m, s in COOLDOWN],
                                                   "suggest": SUGGEST, "sessions": sessions}, indent=2) + "\n")
    print(f"\n{len(movements)} movements, {len(sessions)} sessions. Not referenced anywhere: {unused or 'none'}")


if __name__ == "__main__":
    main()
