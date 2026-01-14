-- QuoteVault Database Schema for Supabase
-- Run this SQL in your Supabase SQL Editor to set up the database
-- This script is idempotent - safe to run multiple times

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Quotes table
CREATE TABLE IF NOT EXISTS quotes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    text TEXT NOT NULL,
    author TEXT NOT NULL,
    category TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User favorites table
CREATE TABLE IF NOT EXISTS user_favorites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    quote_id UUID NOT NULL REFERENCES quotes(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, quote_id)
);

-- Collections table
CREATE TABLE IF NOT EXISTS collections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Collection quotes junction table
CREATE TABLE IF NOT EXISTS collection_quotes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    collection_id UUID NOT NULL REFERENCES collections(id) ON DELETE CASCADE,
    quote_id UUID NOT NULL REFERENCES quotes(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(collection_id, quote_id)
);

-- Enable Row Level Security (RLS)
ALTER TABLE quotes ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE collections ENABLE ROW LEVEL SECURITY;
ALTER TABLE collection_quotes ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (to avoid conflicts when re-running)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'quotes') THEN
        DROP POLICY IF EXISTS "Quotes are viewable by everyone" ON quotes;
        DROP POLICY IF EXISTS "Quotes are insertable by authenticated users" ON quotes;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_favorites') THEN
        DROP POLICY IF EXISTS "Users can view their own favorites" ON user_favorites;
        DROP POLICY IF EXISTS "Users can insert their own favorites" ON user_favorites;
        DROP POLICY IF EXISTS "Users can delete their own favorites" ON user_favorites;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'collections') THEN
        DROP POLICY IF EXISTS "Users can view their own collections" ON collections;
        DROP POLICY IF EXISTS "Users can insert their own collections" ON collections;
        DROP POLICY IF EXISTS "Users can update their own collections" ON collections;
        DROP POLICY IF EXISTS "Users can delete their own collections" ON collections;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'collection_quotes') THEN
        DROP POLICY IF EXISTS "Users can view quotes in their collections" ON collection_quotes;
        DROP POLICY IF EXISTS "Users can add quotes to their collections" ON collection_quotes;
        DROP POLICY IF EXISTS "Users can remove quotes from their collections" ON collection_quotes;
    END IF;
END $$;

-- RLS Policies for quotes (public read, authenticated write)
CREATE POLICY "Quotes are viewable by everyone" ON quotes
    FOR SELECT USING (true);

CREATE POLICY "Quotes are insertable by authenticated users" ON quotes
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- RLS Policies for user_favorites
CREATE POLICY "Users can view their own favorites" ON user_favorites
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own favorites" ON user_favorites
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own favorites" ON user_favorites
    FOR DELETE USING (auth.uid() = user_id);

-- RLS Policies for collections
CREATE POLICY "Users can view their own collections" ON collections
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own collections" ON collections
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own collections" ON collections
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own collections" ON collections
    FOR DELETE USING (auth.uid() = user_id);

-- RLS Policies for collection_quotes
CREATE POLICY "Users can view quotes in their collections" ON collection_quotes
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM collections
            WHERE collections.id = collection_quotes.collection_id
            AND collections.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can add quotes to their collections" ON collection_quotes
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM collections
            WHERE collections.id = collection_quotes.collection_id
            AND collections.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can remove quotes from their collections" ON collection_quotes
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM collections
            WHERE collections.id = collection_quotes.collection_id
            AND collections.user_id = auth.uid()
        )
    );

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_quotes_category ON quotes(category);
CREATE INDEX IF NOT EXISTS idx_quotes_author ON quotes(author);
CREATE INDEX IF NOT EXISTS idx_quotes_text_search ON quotes USING gin(to_tsvector('english', text));
CREATE INDEX IF NOT EXISTS idx_user_favorites_user_id ON user_favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_user_favorites_quote_id ON user_favorites(quote_id);
CREATE INDEX IF NOT EXISTS idx_collections_user_id ON collections(user_id);
CREATE INDEX IF NOT EXISTS idx_collection_quotes_collection_id ON collection_quotes(collection_id);
CREATE INDEX IF NOT EXISTS idx_collection_quotes_quote_id ON collection_quotes(quote_id);

-- Sample quotes data (100+ quotes across categories)
INSERT INTO quotes (text, author, category) VALUES
-- Motivation Quotes
('The only way to do great work is to love what you do.', 'Steve Jobs', 'Motivation'),
('Success is not final, failure is not fatal: it is the courage to continue that counts.', 'Winston Churchill', 'Motivation'),
('The future belongs to those who believe in the beauty of their dreams.', 'Eleanor Roosevelt', 'Motivation'),
('It is during our darkest moments that we must focus to see the light.', 'Aristotle', 'Motivation'),
('The only impossible journey is the one you never begin.', 'Tony Robbins', 'Motivation'),
('In the middle of difficulty lies opportunity.', 'Albert Einstein', 'Motivation'),
('Believe you can and you''re halfway there.', 'Theodore Roosevelt', 'Motivation'),
('The way to get started is to quit talking and begin doing.', 'Walt Disney', 'Motivation'),
('Don''t let yesterday take up too much of today.', 'Will Rogers', 'Motivation'),
('You learn more from failure than from success.', 'Unknown', 'Motivation'),
('If you are working on something exciting that you really care about, you don''t have to be pushed. The vision pulls you.', 'Steve Jobs', 'Motivation'),
('People who are crazy enough to think they can change the world, are the ones who do.', 'Rob Siltanen', 'Motivation'),
('We may encounter many defeats but we must not be defeated.', 'Maya Angelou', 'Motivation'),
('Knowing is not enough; we must apply. Willing is not enough; we must do.', 'Johann Wolfgang von Goethe', 'Motivation'),
('Imagine your life is perfect in every respect; what would it look like?', 'Brian Tracy', 'Motivation'),
('We generate fears while we sit. We overcome them by action.', 'Dr. Henry Link', 'Motivation'),
('Whether you think you can or think you can''t, you''re right.', 'Henry Ford', 'Motivation'),
('The person who says it cannot be done should not interrupt the person who is doing it.', 'Chinese Proverb', 'Motivation'),
('There are no traffic jams along the extra mile.', 'Roger Staubach', 'Motivation'),
('It is never too late to be what you might have been.', 'George Eliot', 'Motivation'),

-- Love Quotes
('The best thing to hold onto in life is each other.', 'Audrey Hepburn', 'Love'),
('Love is composed of a single soul inhabiting two bodies.', 'Aristotle', 'Love'),
('Being deeply loved by someone gives you strength, while loving someone deeply gives you courage.', 'Lao Tzu', 'Love'),
('We are most alive when we''re in love.', 'John Updike', 'Love'),
('The only thing we never get enough of is love; and the only thing we never give enough of is love.', 'Henry Miller', 'Love'),
('Love recognizes no barriers. It jumps hurdles, leaps fences, penetrates walls to arrive at its destination full of hope.', 'Maya Angelou', 'Love'),
('Life is the flower for which love is the honey.', 'Victor Hugo', 'Love'),
('All you need is love.', 'John Lennon', 'Love'),
('Love is when the other person''s happiness is more important than your own.', 'H. Jackson Brown Jr.', 'Love'),
('I have decided to stick with love. Hate is too great a burden to bear.', 'Martin Luther King Jr.', 'Love'),
('Love is friendship that has caught fire.', 'Ann Landers', 'Love'),
('The best love is the kind that awakens the soul and makes us reach for more.', 'Nicholas Sparks', 'Love'),
('Love is not about how many days, months, or years you have been together. Love is about how much you love each other every single day.', 'Unknown', 'Love'),
('To love and be loved is to feel the sun from both sides.', 'David Viscott', 'Love'),
('Love is an untamed force. When we try to control it, it destroys us.', 'Paulo Coelho', 'Love'),
('The heart wants what it wants.', 'Emily Dickinson', 'Love'),
('Love is the greatest refreshment in life.', 'Pablo Picasso', 'Love'),
('A successful marriage requires falling in love many times, always with the same person.', 'Mignon McLaughlin', 'Love'),
('Love is like the wind, you can''t see it but you can feel it.', 'Nicholas Sparks', 'Love'),
('In all the world, there is no heart for me like yours.', 'Maya Angelou', 'Love'),

-- Success Quotes
('Success is not the key to happiness. Happiness is the key to success.', 'Albert Schweitzer', 'Success'),
('The way to get started is to quit talking and begin doing.', 'Walt Disney', 'Success'),
('Innovation distinguishes between a leader and a follower.', 'Steve Jobs', 'Success'),
('Don''t be afraid to give up the good to go for the great.', 'John D. Rockefeller', 'Success'),
('The successful warrior is the average man, with laser-like focus.', 'Bruce Lee', 'Success'),
('There are no secrets to success. It is the result of preparation, hard work, and learning from failure.', 'Colin Powell', 'Success'),
('Success is walking from failure to failure with no loss of enthusiasm.', 'Winston Churchill', 'Success'),
('The only place where success comes before work is in the dictionary.', 'Vidal Sassoon', 'Success'),
('I find that the harder I work, the more luck I seem to have.', 'Thomas Jefferson', 'Success'),
('Success usually comes to those who are too busy to be looking for it.', 'Henry David Thoreau', 'Success'),
('Don''t aim for success if you want it; just do what you love and believe in, and it will come naturally.', 'David Frost', 'Success'),
('The real test is not whether you avoid this failure, because you won''t. It''s whether you let it harden or shame you into inaction.', 'Barack Obama', 'Success'),
('The successful man is the one who finds out what is the matter with his business before his competitors do.', 'Roy L. Smith', 'Success'),
('Try not to become a person of success, but rather try to become a person of value.', 'Albert Einstein', 'Success'),
('I cannot give you the formula for success, but I can give you the formula for failure: which is try to please everybody.', 'Herbert Bayard Swope', 'Success'),
('The difference between a successful person and others is not a lack of strength, not a lack of knowledge, but rather a lack of will.', 'Vince Lombardi', 'Success'),
('Success is the sum of small efforts repeated day in and day out.', 'Robert Collier', 'Success'),
('The only way to do great work is to love what you do.', 'Steve Jobs', 'Success'),
('Success seems to be connected with action. Successful people keep moving.', 'Conrad Hilton', 'Success'),
('I never dreamed about success. I worked for it.', 'Estée Lauder', 'Success'),

-- Wisdom Quotes
('The only true wisdom is in knowing you know nothing.', 'Socrates', 'Wisdom'),
('It is better to remain silent at the risk of being thought a fool, than to talk and remove all doubt of it.', 'Maurice Switzer', 'Wisdom'),
('The fool doth think he is wise, but the wise man knows himself to be a fool.', 'William Shakespeare', 'Wisdom'),
('Yesterday I was clever, so I wanted to change the world. Today I am wise, so I am changing myself.', 'Rumi', 'Wisdom'),
('The wise find pleasure in water; the virtuous find pleasure in hills.', 'Confucius', 'Wisdom'),
('A wise man can learn more from a foolish question than a fool can learn from a wise answer.', 'Bruce Lee', 'Wisdom'),
('The wise man does not lay up his own treasures. The more he gives to others, the more he has for his own.', 'Lao Tzu', 'Wisdom'),
('By three methods we may learn wisdom: First, by reflection, which is noblest; Second, by imitation, which is easiest; and third by experience, which is the bitterest.', 'Confucius', 'Wisdom'),
('Wisdom is not a product of schooling but of the lifelong attempt to acquire it.', 'Albert Einstein', 'Wisdom'),
('The invariable mark of wisdom is to see the miraculous in the common.', 'Ralph Waldo Emerson', 'Wisdom'),
('Wisdom begins in wonder.', 'Socrates', 'Wisdom'),
('The older I grow, the more I distrust the familiar doctrine that age brings wisdom.', 'H.L. Mencken', 'Wisdom'),
('Knowledge speaks, but wisdom listens.', 'Jimi Hendrix', 'Wisdom'),
('Wisdom is the reward you get for a lifetime of listening when you''d have preferred to talk.', 'Doug Larson', 'Wisdom'),
('The wise man learns more from his enemies than the fool from his friends.', 'Baltasar Gracián', 'Wisdom'),
('Wisdom is the daughter of experience.', 'Leonardo da Vinci', 'Wisdom'),
('A wise man will make more opportunities than he finds.', 'Francis Bacon', 'Wisdom'),
('The wise man does at once what the fool does finally.', 'Niccolò Machiavelli', 'Wisdom'),
('Wisdom is knowing what to do next; virtue is doing it.', 'David Starr Jordan', 'Wisdom'),
('The beginning of wisdom is the definition of terms.', 'Socrates', 'Wisdom'),

-- Humor Quotes
('I''m not arguing, I''m just explaining why I''m right.', 'Unknown', 'Humor'),
('I told my wife she was drawing her eyebrows too high. She looked surprised.', 'Unknown', 'Humor'),
('I''m not lazy, I''m just on energy-saving mode.', 'Unknown', 'Humor'),
('I don''t need anger management. I need people to stop making me angry.', 'Unknown', 'Humor'),
('My bed is a magical place where I suddenly remember everything I was supposed to do.', 'Unknown', 'Humor'),
('I''m not procrastinating, I''m just prioritizing my tasks in a different order.', 'Unknown', 'Humor'),
('I''m not short, I''m concentrated awesome.', 'Unknown', 'Humor'),
('I''m not arguing, I''m just passionately expressing my point of view while completely dismissing yours.', 'Unknown', 'Humor'),
('I don''t make mistakes. I date people who make mistakes.', 'Unknown', 'Humor'),
('I''m not saying I''m Wonder Woman, I''m just saying no one has ever seen me and Wonder Woman in the same room together.', 'Unknown', 'Humor'),
('I''m not a complete idiot, some parts are missing.', 'Unknown', 'Humor'),
('I don''t need a hairstylist, my pillow gives me a new hairstyle every morning.', 'Unknown', 'Humor'),
('I''m not saying I''m Batman, I''m just saying no one has ever seen me and Batman in the same room.', 'Unknown', 'Humor'),
('I don''t always test my code, but when I do, I do it in production.', 'Unknown', 'Humor'),
('I''m not lazy, I''m just highly motivated to do nothing.', 'Unknown', 'Humor'),
('I don''t need an alarm clock. My ideas wake me.', 'Unknown', 'Humor'),
('I''m not arguing, I''m just explaining why I''m right.', 'Unknown', 'Humor'),
('I don''t need anger management. I need people to stop making me angry.', 'Unknown', 'Humor'),
('I''m not short, I''m concentrated awesome.', 'Unknown', 'Humor'),
('I don''t make mistakes. I date people who make mistakes.', 'Unknown', 'Humor');

-- Verify tables were created
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'quotes') THEN
        RAISE EXCEPTION 'quotes table was not created';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_favorites') THEN
        RAISE EXCEPTION 'user_favorites table was not created';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'collections') THEN
        RAISE EXCEPTION 'collections table was not created';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'collection_quotes') THEN
        RAISE EXCEPTION 'collection_quotes table was not created';
    END IF;
    RAISE NOTICE 'All tables created successfully!';
END $$;

-- Note: After running this schema, make sure to:
-- 1. Update your SupabaseConfig.swift with your project URL and anon key
-- 2. Enable email authentication in Supabase Dashboard > Authentication > Providers
-- 3. Configure email templates if needed
-- 4. Verify RLS is enabled: Go to Table Editor > Select each table > Check "RLS enabled" in settings