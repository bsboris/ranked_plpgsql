-- "Constants" --

CREATE OR REPLACE FUNCTION ranked_step()
  RETURNS integer AS
$$SELECT 10000::integer$$ LANGUAGE sql IMMUTABLE;

-- Helper functions --

-- Returns product rank in given category
CREATE OR REPLACE FUNCTION ranked_get_rank_in_category(category_id integer, product_id integer) RETURNS integer AS $$
DECLARE
  rank integer;
BEGIN
  SELECT pos INTO rank
    FROM (
      SELECT id, rank() OVER (ORDER BY (category_positions->category_id::text)::integer asc) AS pos
      FROM products
      WHERE category_id = ANY(categories_ids)
    ) AS ss
    WHERE id = product_id;
  RETURN rank;
END
$$ LANGUAGE plpgsql;

-- Returns biggest position value in given category
CREATE OR REPLACE FUNCTION ranked_get_last_position_in_category(category_id integer, OUT last_position integer) RETURNS integer AS $$
BEGIN
  SELECT MAX((category_positions->category_id::varchar)::integer) INTO last_position
    FROM products
    WHERE category_id = ANY(categories_ids);
END
$$ LANGUAGE plpgsql;

-- Return position value for the product with specific rank in given categrory or NULL if such rank wasn't found
CREATE OR REPLACE FUNCTION ranked_get_product_with_rank_in_category(category_id integer, rank integer, OUT pos integer) AS $$
BEGIN
  IF rank <= 0 THEN
    pos := NULL;
    RETURN;
  END IF;
  SELECT category_positions->category_id::text INTO pos
    FROM products
    WHERE category_id = ANY(categories_ids)
    ORDER BY (category_positions->category_id::text)::integer asc
    OFFSET rank - 1
    LIMIT 1;
END
$$ LANGUAGE plpgsql;

-- Puts product to the specified rank in category
CREATE OR REPLACE FUNCTION ranked_set_product_rank_in_category(category_id integer, product_id integer, rank integer) RETURNS void AS $$
DECLARE
  pos integer;
  upper integer;
  lower integer;
BEGIN
  IF rank <= 0 THEN
    RAISE 'Rank should be equal to or greater than 1';
  END IF;
  -- Do nothing if product already has required rank
  IF ranked_get_rank_in_category(category_id, product_id) = rank THEN
    RETURN;
  END IF;
  SELECT ranked_get_product_with_rank_in_category(category_id, rank - 1) INTO upper;
  SELECT ranked_get_product_with_rank_in_category(category_id, rank) INTO lower;
  IF upper IS NULL AND lower IS NULL THEN
    SELECT ranked_get_last_position_in_category(category_id) INTO pos;
    IF pos IS NOT NULL THEN
      pos := pos + ranked_step();
    ELSE
      pos := 0;
    END IF;
  ELSIF upper IS NULL THEN
    pos := 0;
  ELSIF lower IS NULL THEN
    pos := upper + ranked_step();
  ELSE
    pos := ceil((lower - upper) / 2);
  END IF;

  UPDATE products SET category_positions = category_positions || hstore(category_id::text, pos::text) WHERE id = product_id;
END
$$ LANGUAGE plpgsql;

-- Triggers --

-- Checks that product has correct positions for all categories. Also deletes positions for deleted categories.
CREATE OR REPLACE FUNCTION ranked_check_product_positions() RETURNS trigger AS $$
DECLARE
  positions integer[];
  category_id integer;
  last_position integer;
  position integer;
BEGIN
  FOREACH category_id IN ARRAY akeys(NEW.category_positions) LOOP
    IF NOT category_id = ANY(NEW.categories_ids) THEN
      NEW.category_positions := delete(NEW.category_positions, category_id::text);
    END IF;
  END LOOP;

  FOREACH category_id IN ARRAY NEW.categories_ids LOOP
    CONTINUE WHEN (NEW.category_positions ? category_id::text) AND ((NEW.category_positions->category_id::text) IS NOT NULL);
    SELECT ranked_get_last_position_in_category(category_id) INTO last_position;
    IF last_position IS NOT NULL THEN
      position := last_position + ranked_step();
    ELSE
      position := 0;
    END IF;
    NEW.category_positions := NEW.category_positions || hstore(category_id::text, position::text);
  END LOOP;

  RETURN NEW;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER ranked_check_product_positions BEFORE INSERT OR UPDATE ON products FOR EACH ROW EXECUTE PROCEDURE ranked_check_product_positions();

-- Makes sure that every position is unique within category by moving duplicated products down
CREATE OR REPLACE FUNCTION ranked_check_product_positions_uniqueness() RETURNS trigger AS $$
DECLARE
  category_id text;
  existing_productd_id integer;
BEGIN
  FOREACH category_id IN ARRAY akeys(NEW.category_positions) LOOP
    SELECT id INTO existing_productd_id as position
      FROM products
      WHERE id <> NEW.id AND category_positions->category_id = NEW.category_positions->category_id;
    EXIT WHEN existing_productd_id IS NULL;

    UPDATE products
      SET category_positions = category_positions || hstore(category_id, ((category_positions->category_id)::integer + ranked_step())::text)
      WHERE id <> NEW.id AND (category_positions->category_id)::integer >= (NEW.category_positions->category_id::text)::integer;
  END LOOP;
  RETURN NEW;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER ranked_check_product_positions_uniqueness AFTER INSERT OR UPDATE ON products FOR EACH ROW EXECUTE PROCEDURE ranked_check_product_positions_uniqueness();
