-- Baby Maths App - Sample Milestone Seed Data
-- Migration: 0001_seed_maths_milestones.sql
-- This is a SAMPLE with 10 milestones. Full implementation needs 100-120 milestones.

INSERT INTO public.maths_milestones (
  category, 
  title, 
  description, 
  age_months_min, 
  age_months_max, 
  difficulty_level,
  activities, 
  indicators, 
  next_steps,
  sort_order
) VALUES

-- ================================================
-- NUMBER SENSE MILESTONES
-- ================================================

(
  'number-sense',
  'Understands "more" when shown two groups',
  'Child can identify which group has more objects when shown two small collections (2 vs 4, 1 vs 3, etc). This is the foundation of quantity comparison.',
  12,
  18,
  1,
  '[
    {
      "title": "Snack Choice Game",
      "duration_minutes": 5,
      "materials": ["Crackers or berries"],
      "instructions": [
        "Show two plates: one with 2 crackers, one with 5 crackers",
        "Ask: Which plate has MORE crackers?",
        "Let them pick the plate with more",
        "They get to eat that plate!",
        "Repeat with different amounts"
      ],
      "variations": [
        "Use toys instead of food",
        "Try with different objects each day",
        "Let them create the groups for you to choose"
      ],
      "tips": [
        "Make the difference obvious at first (2 vs 6)",
        "Use the word MORE frequently",
        "Celebrate correct choices enthusiastically"
      ]
    },
    {
      "title": "Toy Pile Comparison",
      "duration_minutes": 10,
      "materials": ["Blocks or small toys"],
      "instructions": [
        "Make two piles of toys",
        "Make one obviously bigger",
        "Ask: Which pile has MORE?",
        "Let them point or grab the bigger pile",
        "Talk about why it is more"
      ],
      "variations": [
        "Use stuffed animals",
        "Compare books on shelves",
        "Compare shoes in pairs"
      ],
      "tips": [
        "Start with very different amounts",
        "Use excited voice when saying MORE"
      ]
    }
  ]'::jsonb,
  '["Points to the larger group when asked", "Shows excitement about getting MORE", "Uses the word MORE (even if unclear)", "Consistently chooses the larger amount"]'::jsonb,
  '["Understands LESS or FEWER", "Compares quantities without prompting", "Understands ONE and MANY"]'::jsonb,
  10
),

(
  'number-sense',
  'Subitizes (instantly recognizes) 1-3 objects',
  'Child can look at a small group of 1-3 objects and immediately know how many without counting. This is called subitizing and is a key number sense skill.',
  24,
  30,
  2,
  '[
    {
      "title": "Quick Flash Game",
      "duration_minutes": 5,
      "materials": ["3 small toys or blocks"],
      "instructions": [
        "Show 1 toy briefly, then hide it",
        "Ask: How many did you see?",
        "Celebrate when they say ONE",
        "Repeat with 2 toys, then 3 toys",
        "Keep it fast and fun!"
      ],
      "variations": [
        "Use fingers held up briefly",
        "Use dots on cards",
        "Use stickers on paper"
      ],
      "tips": [
        "Show the objects for just 1-2 seconds",
        "Start with 1, master it, then move to 2",
        "Make it a quick game, not a test"
      ]
    },
    {
      "title": "Dice Dot Recognition",
      "duration_minutes": 10,
      "materials": ["Large foam dice or homemade dice with 1-3 dots"],
      "instructions": [
        "Roll the dice",
        "Say: How many dots?",
        "Encourage them to say the number quickly",
        "Count together if needed",
        "Roll again!"
      ],
      "variations": [
        "Use dot stickers on blocks",
        "Draw dots on cards",
        "Use dominoes"
      ],
      "tips": [
        "Arrange dots in standard patterns (like dice)",
        "Same pattern helps recognition"
      ]
    }
  ]'::jsonb,
  '["Says the number without counting", "Recognizes patterns quickly", "Confident with 1-3", "Doesn''t need to point or count"]'::jsonb,
  '["Subitizes up to 5 objects", "Recognizes dot patterns on dice", "Understands numbers represent quantities"]'::jsonb,
  20
),

-- ================================================
-- COUNTING MILESTONES
-- ================================================

(
  'counting',
  'Rote counts 1-5 (may skip or repeat)',
  'Child can say the number words 1, 2, 3, 4, 5 in order, though they may not yet understand what the numbers mean. This is rote counting - memorizing the sequence.',
  18,
  24,
  1,
  '[
    {
      "title": "Number Song Time",
      "duration_minutes": 5,
      "materials": ["None"],
      "instructions": [
        "Sing counting songs together",
        "Try: One, Two, Buckle My Shoe",
        "Try: Five Little Monkeys",
        "Repeat daily!",
        "Emphasize the number words"
      ],
      "variations": [
        "Count while climbing stairs",
        "Count while clapping",
        "Count during daily routines"
      ],
      "tips": [
        "Repetition is key!",
        "Make it musical and fun",
        "Don''t worry about perfection"
      ]
    },
    {
      "title": "Count and Move",
      "duration_minutes": 10,
      "materials": ["None"],
      "instructions": [
        "Count while doing actions",
        "Jump and count: 1, 2, 3, 4, 5",
        "Clap and count",
        "Stomp and count",
        "Make it a dance!"
      ],
      "variations": [
        "Count spins or twirls",
        "Count hugs or kisses",
        "Count while walking"
      ],
      "tips": [
        "Keep it physical and active",
        "Let them lead sometimes"
      ]
    }
  ]'::jsonb,
  '["Says number words in order", "Attempts to say 1-5", "Enjoys counting songs", "May skip numbers but trying"]'::jsonb,
  '["Counts accurately to 5", "Counts to 10", "Understands one-to-one correspondence"]'::jsonb,
  10
),

(
  'counting',
  'Counts objects 1-5 with one-to-one correspondence',
  'Child touches each object once while saying one number, understanding that each object gets exactly one count. This is a crucial counting skill.',
  24,
  30,
  2,
  '[
    {
      "title": "Counting Snack Time",
      "duration_minutes": 5,
      "materials": ["5 crackers or berries"],
      "instructions": [
        "Place 3-5 snacks on a plate",
        "Count together, touching each one",
        "1... 2... 3...",
        "Say: We have THREE crackers!",
        "Let them eat and count down"
      ],
      "variations": [
        "Count toys before cleanup",
        "Count stairs as you climb",
        "Count body parts"
      ],
      "tips": [
        "Go slowly and deliberately",
        "Touch each object clearly",
        "Celebrate correct counting!"
      ]
    },
    {
      "title": "Toy Line-Up Count",
      "duration_minutes": 10,
      "materials": ["5 small toys"],
      "instructions": [
        "Line up toys in a row",
        "Count together, touching each",
        "Move each toy as you count",
        "Ask: How many toys?",
        "Repeat with different amounts"
      ],
      "variations": [
        "Count books on shelf",
        "Count family members",
        "Count pets or stuffed animals"
      ],
      "tips": [
        "Emphasize ONE touch per number",
        "Start with 3, work up to 5"
      ]
    }
  ]'::jsonb,
  '["Touches each object once", "Says one number per object", "Doesn''t skip or double-count", "Knows last number is the total"]'::jsonb,
  '["Counts to 10 with correspondence", "Counts out a requested amount", "Counts backwards"]'::jsonb,
  20
),

-- ================================================
-- PATTERNS MILESTONES
-- ================================================

(
  'patterns',
  'Recognizes simple patterns (clap-clap-stomp)',
  'Child can identify when actions or objects repeat in a predictable pattern. This is the foundation of pattern recognition.',
  18,
  24,
  1,
  '[
    {
      "title": "Pattern Dance",
      "duration_minutes": 5,
      "materials": ["None"],
      "instructions": [
        "Create a simple pattern: CLAP-CLAP-STOMP",
        "Repeat it several times",
        "Encourage child to copy",
        "Do it together!",
        "Make it silly and fun"
      ],
      "variations": [
        "Try: Jump-Jump-Spin",
        "Try: Pat head-Rub tummy",
        "Try: High five-High five-Hug"
      ],
      "tips": [
        "Keep it short and simple",
        "Repeat many times",
        "Exaggerate your movements"
      ]
    },
    {
      "title": "Sound Patterns",
      "duration_minutes": 10,
      "materials": ["Two toys or instruments"],
      "instructions": [
        "Create pattern with sounds",
        "Drum-Drum-Bell",
        "Repeat clearly",
        "Let them try",
        "Take turns"
      ],
      "variations": [
        "Use kitchen items (pot, spoon)",
        "Use voice (high, low)",
        "Use animal sounds"
      ],
      "tips": [
        "Keep rhythm steady",
        "Visual + auditory is powerful"
      ]
    }
  ]'::jsonb,
  '["Anticipates what comes next", "Copies simple patterns", "Shows excitement when pattern repeats", "May say what comes next"]'::jsonb,
  '["Copies AB patterns", "Creates own patterns", "Extends patterns"]'::jsonb,
  10
),

(
  'patterns',
  'Copies AB patterns with objects',
  'Child can replicate a simple two-element pattern (red-blue-red-blue or circle-square-circle-square) using objects.',
  24,
  30,
  2,
  '[
    {
      "title": "Block Pattern Builder",
      "duration_minutes": 10,
      "materials": ["Blocks in 2 colors"],
      "instructions": [
        "Make a pattern: Red-Blue-Red-Blue",
        "Say: Can you make one like mine?",
        "Help them copy your pattern",
        "Say the colors as you go",
        "Celebrate their pattern!"
      ],
      "variations": [
        "Use different colored objects",
        "Use big-small pattern",
        "Use different shaped blocks"
      ],
      "tips": [
        "Start with just 4 items",
        "Point to each as you name it",
        "Let them fix mistakes themselves"
      ]
    },
    {
      "title": "Sticker Pattern Line",
      "duration_minutes": 10,
      "materials": ["Stickers in 2 types", "Paper"],
      "instructions": [
        "Make a pattern with stickers",
        "Star-Heart-Star-Heart",
        "Show them the pattern",
        "Give them stickers to copy",
        "Talk about what comes next"
      ],
      "variations": [
        "Use stamps instead",
        "Use crayons to draw",
        "Use cut-out shapes"
      ],
      "tips": [
        "Keep pattern visible",
        "Let them keep their creation"
      ]
    }
  ]'::jsonb,
  '["Copies AB pattern correctly", "Recognizes the repeating unit", "Can continue pattern you started", "Says pattern aloud (red-blue-red-blue)"]'::jsonb,
  '["Creates own AB patterns", "Copies ABC patterns", "Extends patterns independently"]'::jsonb,
  20
),

-- ================================================
-- SHAPES MILESTONES
-- ================================================

(
  'shapes',
  'Explores 3D shapes through play',
  'Child manipulates blocks, balls, and containers to understand how different shapes move, stack, and fit together. This is sensory exploration of geometry.',
  6,
  12,
  1,
  '[
    {
      "title": "Block Exploration Time",
      "duration_minutes": 15,
      "materials": ["Variety of blocks: cubes, cylinders, spheres"],
      "instructions": [
        "Offer different shaped blocks",
        "Let baby touch and explore",
        "Stack cubes together",
        "Roll spheres",
        "Talk about what you''re doing"
      ],
      "variations": [
        "Use balls of different sizes",
        "Use soft fabric blocks",
        "Use household items (boxes, cans)"
      ],
      "tips": [
        "Supervise closely",
        "Name shapes: This is a BALL",
        "Let them discover freely"
      ]
    },
    {
      "title": "Shape Sorter Discovery",
      "duration_minutes": 10,
      "materials": ["Shape sorter toy"],
      "instructions": [
        "Show baby the shape sorter",
        "Demonstrate putting shapes in",
        "Let them try (even if wrong hole)",
        "Don''t force - exploration is goal",
        "Celebrate attempts!"
      ],
      "variations": [
        "Use nesting cups",
        "Use stacking rings",
        "Use puzzle with knobs"
      ],
      "tips": [
        "Don''t expect perfection",
        "Focus on exploration",
        "Name shapes as you go"
      ]
    }
  ]'::jsonb,
  '["Reaches for and grasps shapes", "Brings shapes to mouth", "Drops and picks up repeatedly", "Shows interest in different textures"]'::jsonb,
  '["Sorts shapes by similarity", "Attempts shape sorter", "Recognizes familiar shapes"]'::jsonb,
  10
),

(
  'shapes',
  'Recognizes circles and squares',
  'Child can point to circles and squares when asked and may be able to name them. These are typically the first shapes children learn.',
  18,
  24,
  2,
  '[
    {
      "title": "Shape Hunt Around House",
      "duration_minutes": 10,
      "materials": ["None - everyday objects"],
      "instructions": [
        "Walk around your home",
        "Point out circles: clock, plate, button",
        "Point out squares: window, book, pillow",
        "Say: This is a CIRCLE!",
        "Ask: Can you find a circle?"
      ],
      "variations": [
        "Look outside for shapes",
        "Find shapes in books",
        "Find shapes on clothing"
      ],
      "tips": [
        "Make it a treasure hunt",
        "Celebrate each find",
        "Take photos of shapes found"
      ]
    },
    {
      "title": "Shape Snack Time",
      "duration_minutes": 5,
      "materials": ["Foods cut in circles and squares"],
      "instructions": [
        "Cut sandwich into square",
        "Cut cucumber into circles",
        "Name shapes before eating",
        "We''re eating a SQUARE!",
        "Make it fun and tasty"
      ],
      "variations": [
        "Use cookie cutters on fruit",
        "Use cheese slices",
        "Use crackers in shapes"
      ],
      "tips": [
        "Repeat shape names often",
        "Let them help cut (safely)"
      ]
    }
  ]'::jsonb,
  '["Points to circle when asked", "Points to square when asked", "May say CIRCLE or SQUARE", "Finds shapes in environment"]'::jsonb,
  '["Names circles and squares", "Recognizes triangles", "Draws circles"]'::jsonb,
  20
),

-- ================================================
-- SORTING MILESTONES
-- ================================================

(
  'sorting',
  'Sorts by one attribute (color)',
  'Child can group objects by a single attribute like color, putting all red items together and all blue items together.',
  18,
  24,
  2,
  '[
    {
      "title": "Color Sorting Game",
      "duration_minutes": 10,
      "materials": ["Toys in 2 colors", "2 containers"],
      "instructions": [
        "Get toys in red and blue",
        "Get two bowls or boxes",
        "Say: Red toys go HERE",
        "Say: Blue toys go HERE",
        "Sort together, naming colors"
      ],
      "variations": [
        "Sort laundry by color",
        "Sort blocks by color",
        "Sort crayons by color"
      ],
      "tips": [
        "Start with just 2 colors",
        "Make it a game, not a test",
        "It''s OK if they mix it up!"
      ]
    },
    {
      "title": "Snack Sorting",
      "duration_minutes": 5,
      "materials": ["Colorful snacks like Cheerios, fruit"],
      "instructions": [
        "Put colorful snacks on plate",
        "Get small bowls for each color",
        "Sort together",
        "Name colors as you go",
        "Eat when done!"
      ],
      "variations": [
        "Sort M&Ms by color",
        "Sort fruit by type",
        "Sort crackers by shape"
      ],
      "tips": [
        "Make eating the reward",
        "Count each color pile"
      ]
    }
  ]'::jsonb,
  '["Puts same colors together", "Recognizes color as grouping rule", "Can sort with help", "May sort independently"]'::jsonb,
  '["Sorts by size", "Sorts by multiple attributes", "Explains sorting rule"]'::jsonb,
  10
),

-- ================================================
-- MEASUREMENT MILESTONES
-- ================================================

(
  'measurement',
  'Understands big vs. small',
  'Child can identify which of two objects is bigger or smaller. This is the foundation of measurement and comparison.',
  12,
  18,
  1,
  '[
    {
      "title": "Big and Small Toy Compare",
      "duration_minutes": 5,
      "materials": ["2 toys of different sizes"],
      "instructions": [
        "Show two toys: one big, one small",
        "Say: This is the BIG ball",
        "Say: This is the SMALL ball",
        "Ask: Which is BIG?",
        "Let them point or pick"
      ],
      "variations": [
        "Compare stuffed animals",
        "Compare shoes (adult vs baby)",
        "Compare books"
      ],
      "tips": [
        "Make size difference obvious",
        "Use exaggerated voice for BIG",
        "Repeat many times with different objects"
      ]
    },
    {
      "title": "Big and Small Hunt",
      "duration_minutes": 10,
      "materials": ["None - use household items"],
      "instructions": [
        "Find two similar items",
        "One big, one small",
        "Plates, cups, towels, etc.",
        "Show child and compare",
        "BIG towel! SMALL towel!"
      ],
      "variations": [
        "Compare family members (tall/short)",
        "Compare outside items (trees, flowers)",
        "Look at pictures in books"
      ],
      "tips": [
        "Use items from daily life",
        "Make it part of routines"
      ]
    }
  ]'::jsonb,
  '["Points to big when asked", "Points to small when asked", "May say BIG or SMALL", "Understands size difference"]'::jsonb,
  '["Orders 3 items by size", "Uses words bigger/smaller", "Compares own size to objects"]'::jsonb,
  10
);

-- Add more milestones for a complete app (target: 100-120 total)
-- Categories to continue:
-- - counting (more milestones up to counting to 100)
-- - operations (addition, subtraction with objects)
-- - measurement (length, weight, time concepts)
-- - spatial reasoning (positional words, map skills)
-- - More complex patterns (ABC, ABB, etc)
-- - 2D shapes, 3D shapes, shape composition

-- ================================================
-- HELPFUL QUERIES FOR TESTING
-- ================================================

-- Get all milestones for a 25-month-old:
-- SELECT * FROM get_milestones_for_age(25);

-- Get all counting milestones:
-- SELECT * FROM public.maths_milestones WHERE category = 'counting' ORDER BY age_months_min;

-- Get milestones not yet completed by a child:
-- SELECT m.* 
-- FROM public.maths_milestones m
-- LEFT JOIN public.milestone_completions mc ON m.id = mc.milestone_id AND mc.baby_id = '<baby_uuid>'
-- WHERE mc.id IS NULL AND m.age_months_min <= <child_age_months>
-- ORDER BY m.age_months_min;
