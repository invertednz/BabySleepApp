WITH milestone_data (category, title, first_noticed_weeks, worry_after_weeks, activities) AS (
    VALUES
        ('Sensory', 'Brings hands to mouth intentionally', 2, 6, ARRAY[
            'Offer a clean sleeve or soft toy for safe mouthing under supervision.',
            'Encourage self-soothing by placing hands near mouth when calm.'
        ]),
        ('Feeding', 'Demonstrates coordinated suck-swallow-breathe during feeds', 1, 8, ARRAY[
            'Feed in a calm, semi-upright position to support coordination.',
            'Watch for a regular rhythm and pause feeds if coughing or choking occurs.'
        ]),
        ('Social', 'Calms within 30 seconds when picked up by caregiver', 1, 6, ARRAY[
            'Pick up promptly and use skin to skin or close contact to soothe.',
            'Use a calm voice and slow rocking to help them settle.'
        ]),
        ('Fine Motor', 'Holds and shakes a rattle intentionally', 12, 20, ARRAY[
            'Place a lightweight rattle in their hand within reach.',
            'Demonstrate shaking and celebrate any intentional movement.'
        ]),
        ('Fine Motor', 'Transfers objects hand-to-hand', 20, 28, ARRAY[
            'Offer a small toy and gently encourage passing to the other hand.',
            'Model the transfer by showing both hands during play.'
        ]),
        ('Fine Motor', 'Produces a neat release into a container', 28, 36, ARRAY[
            'Use wide mouthed containers and large rings to practice dropping.',
            'Encourage accurate release by demonstrating slowly first.'
        ]),
        ('Motor', 'Rolls both ways (tummy to back and back to tummy)', 20, 28, ARRAY[
            'Place toys to the side to encourage rolling toward them.',
            'Practice supervised tummy time on a soft, safe surface.'
        ]),
        ('Cognitive', 'Explores cause-and-effect intentionally (presses button to watch reaction)', 28, 36, ARRAY[
            'Offer simple cause and effect toys like pop-up boxes or buttons.',
            'Narrate the action and result: "You pushed, it popped!"'
        ]),
        ('Communication', 'Points to request or show interest', 36, 48, ARRAY[
            'Hold a desired toy just out of reach and wait for a point.',
            'When they point, label the object and respond to their interest.'
        ]),
        ('Social', 'Alternates gaze and gesture with caregiver (joint attention)', 36, 48, ARRAY[
            'Follow their gaze and label what they look at.',
            'Pause between comments to allow them to respond.'
        ]),
        ('Social', 'Shows stranger anxiety and prefers familiar adults', 32, 44, ARRAY[
            'Introduce new people slowly and stay close to provide reassurance.',
            'Use a familiar routine or comfort object when meeting new people.'
        ]),
        ('Motor', 'Pulls to a sit from lying independently', 24, 36, ARRAY[
            'Encourage by placing toys to the side when lying down.',
            'Practice gentle assisted sit ups during play sessions.'
        ]),
        ('Fine Motor', 'Bangs two objects together to explore sound', 28, 36, ARRAY[
            'Give two safe objects and imitate their banging to reinforce cause and effect.',
            'Encourage rhythm by tapping along and naming the sound.'
        ]),
        ('Feeding', 'Accepts a variety of food textures (progresses from purees to lumpier foods)', 30, 44, ARRAY[
            'Introduce new textures gradually and alongside familiar foods.',
            'Model eating the new texture and offer small, safe portions.'
        ]),
        ('Communication', 'Imitates simple consonant sounds (for example, "ba", "da")', 20, 28, ARRAY[
            'Repeat and exaggerate sounds and pause to let them try.',
            'Read rhythmic books emphasizing consonant sounds.'
        ]),
        ('Cognitive', 'Uses simple problem solving to move obstacles and reach toys', 36, 48, ARRAY[
            'Show step by step how to move an object and retrieve a toy.',
            'Praise attempts and label the strategy used.'
        ]),
        ('Motor', 'Transitions from crawling to cruising furniture independently', 36, 52, ARRAY[
            'Create safe cruising paths using low, sturdy furniture.',
            'Place motivating toys on adjacent surfaces to encourage movement.'
        ]),
        ('Sensory', 'Shows emerging hand eye coordination by placing objects into slots', 44, 60, ARRAY[
            'Use a shape sorter and demonstrate correct placement.',
            'Start with large shapes that are easy to fit.'
        ]),
        ('Communication', 'Uses gestures to indicate wants (holds up arms, brings toy)', 24, 36, ARRAY[
            'Name the gesture when they use it: "You want up!"',
            'Encourage pairing gestures with single words to build language.'
        ]),
        ('Social', 'Shares attention with caregiver by showing toys', 40, 56, ARRAY[
            'Join their play when they show a toy and comment on it.',
            'Take turns holding and describing the toy to model social sharing.'
        ]),
        ('Motor', 'Walks independently on uneven surfaces with minimal stumbles', 60, 76, ARRAY[
            'Practice walking on grass and carpet to build balance.',
            'Hold hands lightly to encourage confident, cautious steps.'
        ]),
        ('Fine Motor', 'Attempts to scribble spontaneously with a crayon', 52, 68, ARRAY[
            'Provide large, easy grip crayons and paper for free drawing.',
            'Display their scribbles and describe shapes they make.'
        ]),
        ('Cognitive', 'Matches identical pictures or objects', 60, 76, ARRAY[
            'Play matching games with 2 to 4 pairs and increase difficulty gradually.',
            'Use picture cards of familiar items for matching practice.'
        ]),
        ('Communication', 'Uses consistent first words for common people and objects', 36, 52, ARRAY[
            'Reinforce label consistency by using the same word repeatedly.',
            'Read board books that repeat simple nouns and names.'
        ]),
        ('Social', 'Plays alongside another child and begins to imitate their play', 36, 52, ARRAY[
            'Arrange short supervised playtimes with a peer and model imitation.',
            'Praise copying and sharing behaviors during play.'
        ]),
        ('Self-care', 'Helps with dressing by pushing arms or legs through sleeves and pant legs', 48, 64, ARRAY[
            'Give chances to assist during dressing and use simple cues.',
            'Praise participation even if assistance is still needed.'
        ]),
        ('Safety', 'Stops and looks when told "Stop" during supervised practice', 40, 56, ARRAY[
            'Practice the "Stop" command in playful, low-risk situations.',
            'Use a serious tone and reward successful compliance.'
        ]),
        ('Communication', 'Combines two words to request or describe', 52, 68, ARRAY[
            'Expand on their short phrases by modeling slightly longer ones.',
            'Offer choices to prompt combinations: "Milk or water?"'
        ]),
        ('Cognitive', 'Imitates multi-step actions after demonstration', 68, 84, ARRAY[
            'Break actions into small steps and model them slowly.',
            'Use play routines to practice sequences over several days.'
        ]),
        ('Fine Motor', 'Turns pages of a paper book two to three at a time without tearing', 60, 76, ARRAY[
            'Provide sturdy books and show gentle page turning.',
            'Practice hand-over-hand turning before independent attempts.'
        ]),
        ('Motor', 'Kicks a stationary ball forward with intent', 76, 92, ARRAY[
            'Place a large ball and model kicking with the inside of the foot.',
            'Play rolling and kicking games to develop coordination.'
        ]),
        ('Communication', 'Begins to use pronouns inconsistently and starts using "I" and "you"', 72, 88, ARRAY[
            'Model correct pronoun use in sentences and gently recast errors.',
            'Use role play to practice pronouns in context.'
        ]),
        ('Social', 'Plays simple group games with turn taking', 80, 96, ARRAY[
            'Set up small group activities with a clear turn timer.',
            'Praise verbal cues that indicate turn readiness and waiting.'
        ]),
        ('Cognitive', 'Sorts objects by a single feature reliably (color or shape)', 72, 88, ARRAY[
            'Begin with obvious differences and make sorting playful.',
            'Use songs or counting to add fun to sorting tasks.'
        ]),
        ('Self-care', 'Washes hands with help and begins to rinse independently', 80, 96, ARRAY[
            'Use a step stool and post picture steps near the sink.',
            'Sing a short two minute song to encourage thorough washing.'
        ]),
        ('Fine Motor', 'Draws a straight line and tries to copy simple shapes', 80, 96, ARRAY[
            'Provide chunky markers and encourage tracing shapes.',
            'Trace shapes together on paper and in sensory media like sand.'
        ]),
        ('Communication', 'Tells a simple sequence of events with cues', 88, 104, ARRAY[
            'Use photo prompts to support retelling of a recent event.',
            'Ask for beginning, middle, and end to scaffold narrative skills.'
        ]),
        ('Motor', 'Walks up and down a few stairs alternating feet with support', 84, 100, ARRAY[
            'Practice on a low set of steps while holding a hand.',
            'Count steps out loud to support rhythm and sequencing.'
        ]),
        ('Cognitive', 'Understands basic categories such as animals, food, vehicles', 84, 100, ARRAY[
            'Sort toys into category bins during clean up.',
            'Name category labels aloud during play and reading.'
        ]),
        ('Social', 'Shows emerging empathy by offering a comfort action', 92, 108, ARRAY[
            'Label feelings in books and daily interactions.',
            'Praise them when they comfort someone or offer help.'
        ]),
        ('Safety', 'Follows simple household safety rules with reminders', 88, 104, ARRAY[
            'Role play scenarios like "hot equals ouch" and model safe alternatives.',
            'Use consistent short rules and visual cues for reminders.'
        ]),
        ('Cognitive', 'Remembers and follows a three step routine with visual cues', 92, 108, ARRAY[
            'Use picture schedules for familiar routines and practice daily.',
            'Gradually remove one cue at a time to build independence.'
        ]),
        ('Communication', 'Uses descriptive words like big, small, hot, cold appropriately', 96, 112, ARRAY[
            'Highlight adjectives during play and describe objects often.',
            'Play matching games that focus on size or temperature concepts.'
        ]),
        ('Motor', 'Balances on one foot for 5 to 8 seconds', 96, 112, ARRAY[
            'Play balance games on a line or curb and use timed challenges.',
            'Use imaginative prompts such as "statue" to encourage balance.'
        ]),
        ('Self-care', 'Attempts to brush teeth with supervision and growing skill', 96, 112, ARRAY[
            'Model brushing and allow them to try first, then assist for completion.',
            'Use a sand timer or song to reach brushing duration goals.'
        ]),
        ('Social', 'Participates in group story time and attends until the end', 100, 116, ARRAY[
            'Choose short interactive books and ask simple questions.',
            'Sit nearby and point to pictures to maintain attention.'
        ]),
        ('Cognitive', 'Uses counting to solve simple problems', 100, 116, ARRAY[
            'Use snacks or small toys to demonstrate adding and taking away.',
            'Ask "how many more" questions during everyday activities.'
        ]),
        ('Communication', 'Asks "why" and shows curiosity about causes', 110, 126, ARRAY[
            'Answer simply and show safe ways to explore causes.',
            'Use hands on experiments or books to illustrate explanations.'
        ]),
        ('Fine Motor', 'Builds a tower of six or more blocks with growing balance', 98, 114, ARRAY[
            'Use interlocking or large blocks to practice height and stability.',
            'Count blocks aloud as they stack to combine motor and number skills.'
        ]),
        ('Motor', 'Jumps forward with both feet and lands with bent knees', 100, 116, ARRAY[
            'Practice small forward jumps on soft surfaces like carpet.',
            'Play hopping games such as "jump like a frog" to encourage form.'
        ]),
        ('Cognitive', 'Matches a common written symbol to the spoken word', 112, 128, ARRAY[
            'Point out stop signs or restroom symbols and name them aloud.',
            'Use matching cards that pair pictures, symbols, and words.'
        ]),
        ('Self-care', 'Pulls on elastic waist pants and begins to dress with minimal help', 104, 120, ARRAY[
            'Lay out clothes in order and practice each step repeatedly.',
            'Use songs or rhymes to remember left and right when dressing.'
        ]),
        ('Social', 'Begins to prefer certain playmates and forms early friendships', 120, 136, ARRAY[
            'Arrange regular playdates to help friendships grow.',
            'Encourage cooperative games that require sharing roles.'
        ]),
        ('Communication', 'Retells a short story or event with key details without prompts', 124, 140, ARRAY[
            'Practice with questions about beginning, middle, and end.',
            'Use drawings to help map the sequence of events.'
        ]),
        ('Cognitive', 'Solves simple puzzles of six to twelve pieces independently', 108, 124, ARRAY[
            'Offer age appropriate puzzles with clear pictures.',
            'Sit together to demonstrate one or two strategies then let them try.'
        ]),
        ('Safety', 'Recognizes emergency contact information and practices how to get help', 140, 156, ARRAY[
            'Teach a simple sequence: find an adult and tell them who to call.',
            'Role play asking for help in safe, supervised sessions.'
        ]),
        ('Fine Motor', 'Threads large beads and begins lacing activities', 120, 136, ARRAY[
            'Use large beads with a string or soft laces to practice threading.',
            'Demonstrate slowly and make a game of bead colors and patterns.'
        ]),
        ('Motor', 'Rides a balance bike confidently without support', 140, 156, ARRAY[
            'Use a bike with a low seat so their feet can reach the ground.',
            'Practice on gentle slopes to develop momentum and steering skills.'
        ]),
        ('Communication', 'Uses future tense and talks about upcoming plans', 152, 168, ARRAY[
            'Talk about tomorrow and next week during morning routines.',
            'Use a simple calendar to mark special events and count down.'
        ]),
        ('Social', 'Engages in cooperative multi step pretend play with peers', 156, 172, ARRAY[
            'Provide open ended props and encourage role switching.',
            'Narrate and expand their play to introduce new scenarios and vocabulary.'
        ]),

        -- Additional unique milestones (carefully vetted to avoid duplicates)
        -- Communication
        ('Communication', 'Uses conjunctions like "and" and "because" in sentences', 216, 236, ARRAY[
            'Model connecting ideas with "and" and "because" during play and routines.',
            'Prompt for reasons: "I wore boots because it was raining."'
        ]),
        ('Communication', 'Asks and answers "who", "what", and "where" questions consistently', 200, 220, ARRAY[
            'Pause during books to ask who/what/where questions and let them answer.',
            'Play scavenger hunts: "Where is the blue block?"'
        ]),
        ('Communication', 'Uses temporal words "first", "then", and "last" when retelling events', 216, 236, ARRAY[
            'Use visual sequence cards labeled first/then/last.',
            'After routines, prompt retellings using temporal words.'
        ]),

        -- Phonological awareness / Literacy foundations
        ('Cognitive', 'Claps syllables in familiar words (2–3 syllables)', 208, 228, ARRAY[
            'Clap names of family members and favorite foods.',
            'Sort picture cards by number of claps/syllables.'
        ]),
        ('Cognitive', 'Blends onset–rime to make words (e.g., c + at → cat)', 232, 252, ARRAY[
            'Play "Say it fast" games: /m/ + "ap" → map.',
            'Use magnets to join first sound to rime chunks.'
        ]),
        ('Cognitive', 'Identifies ending sounds in common words', 236, 256, ARRAY[
            'Play sound match: "What ends with /t/? cat, sun, or mop?"',
            'Emphasize final sounds while reading aloud.'
        ]),

        -- Early mathematics
        ('Cognitive', 'Writes numbers 0–10', 228, 248, ARRAY[
            'Trace numbers in sand, shaving cream, or with finger on foggy glass.',
            'Use dotted lines or number cards to copy.'
        ]),
        ('Cognitive', 'Orders numbers 1–10 in sequence', 216, 236, ARRAY[
            'Arrange number cards on the floor and have them place missing ones.',
            'Build number lines with blocks labeled 1–10.'
        ]),
        ('Cognitive', 'Counts backward from 10 to 0', 232, 252, ARRAY[
            'Countdown before a jump or rocket blast-off.',
            'Sing backward counting songs (10 little rockets).'
        ]),
        ('Cognitive', 'Understands zero as "none"', 220, 240, ARRAY[
            'Ask "How many crackers left?" when the plate is empty to label zero.',
            'Play quick games showing empty vs. some in cups.'
        ]),
        ('Cognitive', 'Compares quantities using "more", "less", and "same" for sets up to 10', 220, 240, ARRAY[
            'Compare snack piles: "Who has more?" and count to check.',
            'Use ten-frames to show equal vs. not equal.'
        ]),
        ('Cognitive', 'Understands ordinal positions first through fifth', 224, 244, ARRAY[
            'Line up toys and label positions: first, second, third.',
            'Use race tracks with cars to talk about order.'
        ]),
        ('Cognitive', 'Measures using nonstandard units (blocks, footsteps)', 232, 252, ARRAY[
            'Measure tables with blocks and compare lengths.',
            'Count footsteps from couch to door and record.'
        ]),

        -- Literacy / Letters
        ('Cognitive', 'Names at least 10 lowercase letters', 220, 240, ARRAY[
            'Play lowercase letter bingo or memory.',
            'Label shelves and bins with lowercase letter starters.'
        ]),
        ('Cognitive', 'Writes several uppercase letters independently', 236, 256, ARRAY[
            'Practice high-contrast letters with chalk on black paper.',
            'Use box guides to help size and placement.'
        ]),

        -- Executive function
        ('Cognitive', 'Sorts and classifies by three attributes (e.g., color, size, shape)', 236, 256, ARRAY[
            'Give mixed buttons to sort by multiple features.',
            'Use simple Venn diagrams with toys to classify.'
        ]),
        ('Cognitive', 'Sustains attention to a structured activity for about 10 minutes', 236, 256, ARRAY[
            'Increase activity time gradually using timers.',
            'Choose engaging tasks like puzzles or matching games.'
        ]),

        -- Social / Emotional
        ('Social', 'Waits for a turn for 3–5 minutes with minimal reminders', 216, 236, ARRAY[
            'Use visual timers during games and praise waiting.',
            'Model phrases for waiting: "I will wait my turn."'
        ]),
        ('Social', 'Uses polite words like "please" and "thank you" without reminders', 208, 228, ARRAY[
            'Model and acknowledge polite words throughout the day.',
            'Play restaurant/pretend store to practice courteous phrases.'
        ]),
        ('Social', 'States personal preferences and opinions respectfully', 232, 252, ARRAY[
            'Offer choices and prompt using "I like..." statements.',
            'Praise respectful disagreement and perspective-taking.'
        ]),

        -- Gross Motor
        ('Motor', 'Performs 5 jumping jacks with coordinated arms and legs', 232, 252, ARRAY[
            'Practice slow jump-and-clap patterns before full jacks.',
            'Use music with a steady beat to cue movements.'
        ]),
        ('Motor', 'Leaps over a 6-inch obstacle with two-foot takeoff and landing', 220, 240, ARRAY[
            'Set up tape or small foam blocks as hurdles.',
            'Cue "bend, jump, land softly" and measure distance.'
        ]),
        ('Motor', 'Runs 50 feet with smooth changes in direction without falling', 212, 232, ARRAY[
            'Set up cone courses and play follow-the-leader runs.',
            'Practice starting, stopping, and turning safely.'
        ]),
        ('Motor', 'Walks a taped line or balance beam forward for 10 feet', 224, 244, ARRAY[
            'Make floor balance lines with painters tape.',
            'Add challenges: heel-to-toe, carry a light object.'
        ]),

        -- Fine Motor
        ('Fine Motor', 'Cuts along a zigzag line within 1/4 inch of the line', 228, 248, ARRAY[
            'Draw bold zigzag paths and cut slowly with child-safe scissors.',
            'Turn the paper with the helper hand while cutting.'
        ]),
        ('Fine Motor', 'Uses a glue stick neatly to outline and paste', 216, 236, ARRAY[
            'Teach "dot, dot, not a lot" for glue control.',
            'Outline shapes first, then paste within lines.'
        ]),
        ('Fine Motor', 'Ties a simple knot in a shoelace or string', 236, 256, ARRAY[
            'Use thick laces and a practice board at first.',
            'Teach one step at a time before introducing bows.'
        ]),
        ('Fine Motor', 'Copies a diamond shape', 248, 268, ARRAY[
            'Trace large diamonds and fade supports to free-draw.',
            'Use geoboards or sticks to build the shape first.'
        ]),

        -- Self-care / Adaptive
        ('Self-care', 'Drinks from an open cup without spilling most of the time', 72, 88, ARRAY[
            'Practice with small open cups and small amounts of water.',
            'Offer frequent chances to drink while seated at the table.'
        ]),
        ('Self-care', 'Puts on and takes off a simple coat independently', 208, 228, ARRAY[
            'Teach the flip-over coat trick and practice daily.',
            'Lay out coats with the tag at the neck for orientation.'
        ]),
        ('Self-care', 'Puts toothpaste on toothbrush with supervision', 216, 236, ARRAY[
            'Use a pea-sized dot and show where to place it on the brush.',
            'Create a visual routine card for the steps.'
        ]),

        -- Safety / Personal information
        ('Cognitive', 'Identifies safe vs. unsafe household substances and asks before touching', 236, 256, ARRAY[
            'Sort pictures: safe to touch vs. ask an adult first.',
            'Practice the phrase: "I will ask before I touch."'
        ]),

        -- Additional early academics
        ('Cognitive', 'Subitizes quantities up to 3–4 without counting', 212, 232, ARRAY[
            'Flash dot cards briefly and have them say the number.',
            'Play quick-look games with dice faces and dominoes.'
        ]),
        ('Cognitive', 'Names 8 or more colors (e.g., pink, purple, orange, brown)', 200, 220, ARRAY[
            'Play color hunt around the house or outside.',
            'Sort crayons by color and name each pile.'
        ]),
        ('Cognitive', 'Reads common environmental print (e.g., STOP, EXIT, logos)', 224, 244, ARRAY[
            'Point out environmental print on walks and label it together.',
            'Make a picture book of local signs and store logos.'
        ])
),
inserted_milestones AS (
    INSERT INTO public.milestones (category, title, first_noticed_weeks, worry_after_weeks)
    SELECT category, title, first_noticed_weeks, worry_after_weeks FROM milestone_data
    RETURNING id, title
)
INSERT INTO public.milestone_activities (milestone_id, description)
SELECT im.id, unnest(md.activities)
FROM milestone_data md
JOIN inserted_milestones im ON md.title = im.title;
