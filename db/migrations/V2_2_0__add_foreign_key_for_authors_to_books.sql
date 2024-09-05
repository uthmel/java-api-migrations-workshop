ALTER TABLE Books
ADD COLUMN author_id INTEGER;

ALTER TABLE Books
ADD CONSTRAINT fk_author_id
    FOREIGN KEY (author_id)
    REFERENCES Authors(id);
