WITH milestone_data (category, title, first_noticed_weeks, worry_after_weeks, activities) AS (
    VALUES
        -- Communication (3.5y - 5y)
        ('Communication', 'Uses plurals and past tense correctly in conversation', 190, 210, ARRAY['Model correct grammar in everyday talk.', 'Expand on what they say: "We walked to the park yesterday."']),
        ('Communication', 'Understands prepositions like under, behind, between', 192, 212, ARRAY['Play a hide-and-seek game with toys (under the chair, behind the pillow).', 'Give simple location clues during cleanup.']),
        ('Communication', 'Follows a three-step direction without gestures', 196, 216, ARRAY['Start with two-step directions and add a third step.', 'Use visual checklists for routines.']),
        ('Communication', 'Asks and answers “how” and “when” questions', 200, 220, ARRAY['Read picture books and pause to ask “How did that happen?”', 'Encourage them to ask follow-up questions.']),
        ('Communication', 'Tells a story with a clear beginning, middle, and end', 208, 230, ARRAY['Use story sequence cards.', 'Encourage retelling daily events in order.']),
        ('Communication', 'Is understood by unfamiliar listeners most of the time (90%)', 210, 232, ARRAY['Model slow, clear speech.', 'Practice new words during play.']),
        ('Communication', 'Uses comparative and superlative adjectives (bigger, biggest)', 212, 232, ARRAY['Compare sizes while building with blocks.', 'Sort items from smallest to largest.']),
        ('Communication', 'Uses future forms (will) and simple conditionals (if/then) in speech', 224, 244, ARRAY['Talk about plans: "We will go after lunch."', 'Play pretend with “If we are astronauts, then we wear helmets.”']),
        ('Communication', 'Understands and produces rhyming words', 228, 248, ARRAY['Play a rhyming game during car rides.', 'Sing nursery rhymes emphasizing rhyming pairs.']),
        ('Communication', 'Identifies the first sound of common words (phonological awareness)', 236, 256, ARRAY['Play "I spy with my little eye something that starts with /b/".', 'Sort picture cards by beginning sound.']),
        
        -- Cognitive / Early academics
        ('Cognitive', 'Counts out loud to 20 or higher', 200, 220, ARRAY['Count steps, toys, or snacks or clap while counting.', 'Make counting part of daily routines.']),
        ('Cognitive', 'One-to-one counting of 10–20 objects', 204, 224, ARRAY['Touch each object as they count.', 'Use snack time for counting practice.']),
        ('Cognitive', 'Recognizes numerals 0–10', 206, 226, ARRAY['Play number matching games.', 'Post a number line on the wall and reference it.']),
        ('Cognitive', 'Recognizes numerals 0–20', 220, 240, ARRAY['Use calendar numbers to point and name.', 'Play “number hunt” around the house.']),
        ('Cognitive', 'Understands simple addition with objects (e.g., 1+1, 2+1)', 216, 236, ARRAY['Use snacks or blocks to join sets and count all.', 'Say math stories during play.']),
        ('Cognitive', 'Understands taking away (simple subtraction) with objects', 220, 240, ARRAY['“You have 3 crackers, eat 1, how many left?”', 'Play “store” and give change with counters.']),
        ('Cognitive', 'Creates and extends patterns (AB, AAB, ABB, ABC)', 210, 230, ARRAY['Make bead or movement patterns to copy and extend.', 'Use patterned stickers or colored blocks.']),
        ('Cognitive', 'Sorts by two attributes (e.g., color and size)', 214, 234, ARRAY['Sort buttons by color and by size in trays.', 'Use Venn diagrams with toys.']),
        ('Cognitive', 'Compares length/weight and uses words longer/shorter, heavier/lighter', 218, 238, ARRAY['Use a balance scale with toys.', 'Line up strings to compare which is longer.']),
        ('Cognitive', 'Understands time words yesterday/today/tomorrow', 208, 228, ARRAY['Use a simple calendar to mark events.', 'Talk each morning about what will happen today.']),
        ('Cognitive', 'Understands parts of the day (morning/afternoon/evening)', 208, 228, ARRAY['Make a picture schedule by time of day.', 'Ask “What do we do in the evening?”']),
        ('Cognitive', 'Understands position and sides (left/right) on self', 224, 244, ARRAY['Sticker on the right hand to practice right/left.', 'Give body-side directions during dance.']),
        ('Cognitive', 'Completes a 20–24 piece interlocking puzzle', 212, 232, ARRAY['Start with edge pieces first.', 'Sort by color or picture section to plan.']),
        ('Cognitive', 'Recognizes common shapes including triangle, rectangle, oval, diamond', 206, 226, ARRAY['Shape hunt around the house.', 'Trace shapes on paper and label them.']),
        ('Cognitive', 'Recalls a 3-step sequence of events', 210, 230, ARRAY['Ask them to repeat the plan (“First bath, then PJs, then book”).', 'Use picture cards to sequence routines.']),
        ('Cognitive', 'Tells how two objects are alike/different (function, features)', 216, 236, ARRAY['Compare two toys: how are they the same or different?', 'Make simple comparison charts.']),
        ('Cognitive', 'Understands basic map/space ideas (near/far, here/there)', 226, 246, ARRAY['Follow a simple treasure map at home.', 'Use words near/far while walking.']),
        ('Cognitive', 'Understands simple estimation (about how many)', 236, 256, ARRAY['Guess how many blocks, then count to check.', 'Use jars of items for estimation play.']),
        
        -- Literacy / Phonological awareness
        ('Cognitive', 'Recognizes own name and most uppercase letters', 200, 220, ARRAY['Use name puzzles and magnetic letters.', 'Label their art space and belongings.']),
        ('Cognitive', 'Matches uppercase to lowercase letters', 210, 230, ARRAY['Play a letter matching memory game.', 'Sort letter tiles into pairs.']),
        ('Cognitive', 'Identifies some letter sounds (consonants and vowels)', 220, 240, ARRAY['Practice one new sound a week.', 'Connect sounds to pictures (m for moon).']),
        ('Cognitive', 'Tracks print left-to-right and top-to-bottom when reading', 212, 232, ARRAY['Point under each word while reading.', 'Use finger-tracking while they read with you.']),
        ('Cognitive', 'Produces a rhyming word for a common prompt', 232, 252, ARRAY['Give a word and ask for a rhyme.', 'Use picture cards in a silly rhyme game.']),
        
        -- Gross Motor (3.5y - 5y)
        ('Motor', 'Balances on one foot for 8–10 seconds', 200, 220, ARRAY['Play “statue” on one foot.', 'Pretend to be flamingos in a mirror.']),
        ('Motor', 'Hops forward 5–10 times on one foot', 208, 228, ARRAY['Hopscotch lines or floor tape.', 'Count consecutive hops as a challenge.']),
        ('Motor', 'Skips smoothly for 10 feet with alternating feet', 212, 232, ARRAY['Teach “step-hop, step-hop.”', 'Skip to music with a steady beat.']),
        ('Motor', 'Gallops leading with either foot', 206, 226, ARRAY['Play horse gallop games.', 'Switch lead foot during songs.']),
        ('Motor', 'Jumps forward more than 24 inches with two-foot takeoff', 206, 226, ARRAY['Make jump lines with tape and measure distance.', 'Practice soft landings with bent knees.']),
        ('Motor', 'Throws a ball overhead toward a target 10 feet away', 210, 230, ARRAY['Aim at a large target (laundry basket).', 'Practice stepping with the opposite foot.']),
        ('Motor', 'Catches a small ball with hands only (no trapping)', 216, 236, ARRAY['Use a slightly deflated ball first.', 'Stand closer then gradually back up.']),
        ('Motor', 'Walks on tiptoes for 15 feet', 206, 226, ARRAY['Tiptoe balance beam with tape on floor.', 'Pretend to sneak quietly like a cat.']),
        ('Motor', 'Climbs playground ladder alternating feet', 204, 224, ARRAY['Practice on low rungs with a spotter.', 'Use climbing walls with big handholds.']),
        ('Motor', 'Rides a bicycle with training wheels or pedals a balance bike well', 228, 248, ARRAY['Practice braking and starting.', 'Use gentle slopes to learn balancing.']),
        
        -- Fine Motor (3.5y - 5y)
        ('Fine Motor', 'Uses mature tripod grasp when drawing or writing', 200, 220, ARRAY['Use short crayons/pencils to promote tripod grasp.', 'Strengthen fingers with play dough.']),
        ('Fine Motor', 'Cuts along a curved line accurately', 206, 226, ARRAY['Draw wide curved paths to cut.', 'Use child-safe scissors and thick paper.']),
        ('Fine Motor', 'Cuts out simple shapes (circle or square) within 1/4 inch of the line', 212, 232, ARRAY['Turn the paper with the helper hand while cutting.', 'Trace bold shapes before cutting.']),
        ('Fine Motor', 'Buttons and unbuttons small buttons independently', 208, 228, ARRAY['Practice with a dressing board.', 'Start with larger buttons and progress smaller.']),
        ('Fine Motor', 'Zips and unzips a jacket independently', 206, 226, ARRAY['Start the zipper for them, then let them pull.', 'Practice aligning the zipper box.']),
        ('Fine Motor', 'Strings small beads in a repeating pattern', 204, 224, ARRAY['Use pipe cleaners to make it easier at first.', 'Say the color names as they bead.']),
        ('Fine Motor', 'Folds paper in half matching corners', 210, 230, ARRAY['Draw a line to fold on.', 'Use stickers to show corners to match.']),
        ('Fine Motor', 'Colors within boundaries most of the time', 214, 234, ARRAY['Use thick outlines to color inside.', 'Encourage slow, careful strokes.']),
        ('Fine Motor', 'Draws a triangle', 220, 240, ARRAY['Teach V-shape and connect the top.', 'Trace triangles before free-drawing.']),
        ('Fine Motor', 'Writes first name with mostly correct letter formation', 228, 248, ARRAY['Use a name model with boxes per letter.', 'Start with uppercase then add lowercase.']),
        ('Fine Motor', 'Copies letters like A, H, T, O, X', 224, 244, ARRAY['Write high-contrast letters to trace.', 'Use sand trays or chalk to practice.']),
        
        -- Social / Emotional
        ('Social', 'Separates from caregiver without distress in familiar settings', 196, 216, ARRAY['Create a short, consistent goodbye routine.', 'Return on time to build trust.']),
        ('Social', 'Takes turns and shares with minimal adult prompting', 200, 220, ARRAY['Use timers for turn-taking.', 'Praise spontaneous sharing.']),
        ('Social', 'Plays cooperatively with assigned roles (cooperative pretend play)', 206, 226, ARRAY['Provide open-ended props (doctor kit, store).', 'Rotate roles during play.']),
        ('Social', 'Understands and follows rules in simple board/card games', 208, 228, ARRAY['Choose games with few, clear rules.', 'Model sportsmanship and taking turns.']),
        ('Social', 'Identifies and labels own and others’ emotions', 204, 224, ARRAY['Use emotion cards and mirror faces.', 'Name feelings during real situations.']),
        ('Social', 'Uses words to resolve conflicts with peers', 214, 234, ARRAY['Teach phrases like “I don''t like that.”', 'Practice with role-play and puppets.']),
        ('Social', 'Shows empathy and helps others (comforts, offers help)', 206, 226, ARRAY['Point out helpful behaviors and praise them.', 'Read books about kindness and discuss.']),
        ('Social', 'Follows multi-step classroom routines independently', 224, 244, ARRAY['Post picture routines.', 'Practice transitions with songs.']),
        
        -- Self-care / Adaptive
        ('Self-care', 'Toilets independently during the day', 196, 216, ARRAY['Use a sticker chart for success.', 'Practice handwashing after every attempt.']),
        ('Self-care', 'Washes and dries hands independently', 196, 216, ARRAY['Post visual steps near the sink.', 'Sing a 20-second handwashing song.']),
        ('Self-care', 'Brushes teeth with minimal assistance', 200, 220, ARRAY['Use a sand timer or app for 2 minutes.', 'Let them brush first, then a parent “checks.”']),
        ('Self-care', 'Dresses self including socks and shoes (may need help with laces)', 208, 228, ARRAY['Lay out clothes in order.', 'Practice putting shoes on the correct feet.']),
        ('Self-care', 'Pours water from a small pitcher without spilling much', 206, 226, ARRAY['Practice pouring in the bath or sink.', 'Use small pitchers and wide cups.']),
        ('Self-care', 'Spreads with a child-safe knife (e.g., butter on toast)', 212, 232, ARRAY['Use soft spreadables first.', 'Hold the bread steady with the helper hand.']),
        ('Self-care', 'Uses fork and spoon neatly with minimal spills', 206, 226, ARRAY['Offer thicker foods to practice scooping.', 'Model proper grip and pace.']),
        ('Self-care', 'Blows nose and discards tissue with reminders', 206, 226, ARRAY['Practice blowing through a straw as a warm-up.', 'Post a visual reminder routine.']),
        ('Self-care', 'Ties a simple bow or begins shoe-tying steps', 248, 268, ARRAY['Use a practice board with thick laces.', 'Teach one step at a time (bunny ears).']),
        
        -- Safety / Personal information
        ('Cognitive', 'Understands basic road safety: stop, look both ways, hold hands', 210, 230, ARRAY['Practice at quiet crosswalks.', 'Make a “stop-look-listen” chant.']),
        ('Cognitive', 'Knows personal information: first/last name, age, and parent names', 216, 236, ARRAY['Practice with a “Me” book.', 'Play a quiz game at dinner.']),
        ('Cognitive', 'Learning home address and/or phone number', 232, 252, ARRAY['Make a song with their address/number.', 'Practice reciting during car rides.'])
), inserted_milestones AS (
    INSERT INTO public.milestones (category, title, first_noticed_weeks, worry_after_weeks)
    SELECT category, title, first_noticed_weeks, worry_after_weeks FROM milestone_data
    RETURNING id, title
)
INSERT INTO public.milestone_activities (milestone_id, description)
SELECT im.id, unnest(md.activities)
FROM milestone_data md
JOIN inserted_milestones im ON md.title = im.title;

inserted_milestones AS (
    INSERT INTO public.milestones (category, title, first_noticed_weeks, worry_after_weeks)
    SELECT md.category, md.title, md.first_noticed_weeks, md.worry_after_weeks
    FROM milestone_data md
    LEFT JOIN public.milestones m
      ON m.category = md.category AND m.title = md.title
    WHERE m.id IS NULL
    RETURNING id, title, category
)
INSERT INTO public.milestone_activities (milestone_id, description)
SELECT im.id, unnest(md.activities)
FROM milestone_data md
JOIN inserted_milestones im ON md.title = im.title AND md.category = im.category;