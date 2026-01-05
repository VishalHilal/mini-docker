-- Initialize PostgreSQL database for Mini-Docker
-- This script runs automatically when the PostgreSQL container starts

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Create schemas
CREATE SCHEMA IF NOT EXISTS minidocker;
SET search_path TO minidocker, public;

-- Images table
CREATE TABLE IF NOT EXISTS images (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL UNIQUE,
    tag VARCHAR(50) DEFAULT 'latest',
    size BIGINT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb,
    layers TEXT[] DEFAULT ARRAY[]::TEXT[]
);

-- Containers table
CREATE TABLE IF NOT EXISTS containers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    image_id UUID REFERENCES images(id) ON DELETE CASCADE,
    status VARCHAR(50) DEFAULT 'created',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    started_at TIMESTAMP WITH TIME ZONE,
    stopped_at TIMESTAMP WITH TIME ZONE,
    command TEXT[] DEFAULT ARRAY[]::TEXT[],
    environment JSONB DEFAULT '{}'::jsonb,
    ports JSONB DEFAULT '{}'::jsonb,
    volumes JSONB DEFAULT '{}'::jsonb,
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Build logs table
CREATE TABLE IF NOT EXISTS build_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    image_id UUID REFERENCES images(id) ON DELETE CASCADE,
    step INTEGER NOT NULL,
    command TEXT,
    output TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Container logs table
CREATE TABLE IF NOT EXISTS container_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    container_id UUID REFERENCES containers(id) ON DELETE CASCADE,
    stream VARCHAR(10) CHECK (stream IN ('stdout', 'stderr')),
    message TEXT,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_images_name ON images(name);
CREATE INDEX IF NOT EXISTS idx_images_created_at ON images(created_at);
CREATE INDEX IF NOT EXISTS idx_containers_image_id ON containers(image_id);
CREATE INDEX IF NOT EXISTS idx_containers_status ON containers(status);
CREATE INDEX IF NOT EXISTS idx_containers_created_at ON containers(created_at);
CREATE INDEX IF NOT EXISTS idx_build_logs_image_id ON build_logs(image_id);
CREATE INDEX IF NOT EXISTS idx_container_logs_container_id ON container_logs(container_id);
CREATE INDEX IF NOT EXISTS idx_container_logs_timestamp ON container_logs(timestamp);

-- Trigger for updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_images_updated_at BEFORE UPDATE
    ON images FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert sample data (optional)
INSERT INTO images (name, tag, size, metadata) VALUES 
('hello-world', 'latest', 1024, '{"author": "mini-docker", "description": "Sample hello world image"}')
ON CONFLICT (name, tag) DO NOTHING;

-- Grant permissions (adjust username as needed)
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA minidocker TO minidocker;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA minidocker TO minidocker;

-- Create views for common queries
CREATE OR REPLACE VIEW container_stats AS
SELECT 
    c.id,
    c.name,
    c.status,
    i.name as image_name,
    i.tag as image_tag,
    c.created_at,
    c.started_at,
    c.stopped_at,
    CASE 
        WHEN c.started_at IS NOT NULL AND c.stopped_at IS NULL THEN 
            EXTRACT(EPOCH FROM (NOW() - c.started_at))::INTEGER
        ELSE NULL
    END as runtime_seconds
FROM containers c
LEFT JOIN images i ON c.image_id = i.id;

-- Create function to get container statistics
CREATE OR REPLACE FUNCTION get_container_stats()
RETURNS TABLE(
    total_containers BIGINT,
    running_containers BIGINT,
    stopped_containers BIGINT,
    total_images BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (SELECT COUNT(*) FROM containers) as total_containers,
        (SELECT COUNT(*) FROM containers WHERE status = 'running') as running_containers,
        (SELECT COUNT(*) FROM containers WHERE status = 'stopped') as stopped_containers,
        (SELECT COUNT(*) FROM images) as total_images;
END;
$$ LANGUAGE plpgsql;

COMMIT;
