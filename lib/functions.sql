-- "Constants" --

CREATE OR REPLACE FUNCTION ranked_step()
  RETURNS integer AS
$$SELECT 10000::integer$$ LANGUAGE sql IMMUTABLE;

-- Helper functions --

CREATE OR REPLACE FUNCTION ranked_hstore_diff(el1 hstore, el2 hstore) RETURNS hstore AS $$
BEGIN
  RETURN (el1 - el2) || (el2 - el1);
END
$$ LANGUAGE plpgsql;

-- Returns product rank in given category
CREATE OR REPLACE FUNCTION ranked_get_rank_in_category(category_id integer, product_id integer, OUT rank integer) RETURNS integer AS $$
DECLARE
  product_position integer;
BEGIN
  SELECT (category_positions->category_id::text)::integer INTO product_position FROM products WHERE id = product_id;

  SELECT COUNT(1) INTO rank
    FROM products
    WHERE categories_ids @> ARRAY[category_id] AND (category_positions->category_id::text)::integer <= product_position;
  IF rank = 0 THEN
    rank := NULL;
  END IF;
END
$$ LANGUAGE plpgsql;

-- Returns biggest position value in given category
CREATE OR REPLACE FUNCTION ranked_get_last_position_in_category(category_id integer, OUT last_position integer) RETURNS integer AS $$
BEGIN
  SELECT MAX((category_positions->category_id::varchar)::integer) INTO last_position
    FROM products
    WHERE categories_ids @> ARRAY[category_id];
END
$$ LANGUAGE plpgsql;

-- Return position value for the product with specific rank in given categrory or NULL if such rank wasn't found
CREATE OR REPLACE FUNCTION ranked_get_position_for_rank_in_category(category_id integer, rank integer, OUT pos integer) AS $$
BEGIN
  IF rank <= 0 THEN
    pos := NULL;
    RETURN;
  END IF;
  SELECT category_positions->category_id::text INTO pos
    FROM products
    WHERE categories_ids @> ARRAY[category_id]
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
  SELECT ranked_get_position_for_rank_in_category(category_id, rank - 1) INTO upper;
  SELECT ranked_get_position_for_rank_in_category(category_id, rank) INTO lower;
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
    pos := upper + ceil((lower - upper) / 2);
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
  IF array_length(akeys(NEW.category_positions), 1) > 0 THEN
    FOREACH category_id IN ARRAY akeys(NEW.category_positions) LOOP
      IF NOT NEW.categories_ids @> ARRAY[category_id] category_id THEN
        NEW.category_positions := delete(NEW.category_positions, category_id::text);
      END IF;
    END LOOP;
  END IF;

  IF array_length(NEW.categories_ids, 1) > 0 THEN
    FOREACH category_id IN ARRAY NEW.categories_ids LOOP
      CONTINUE WHEN (NEW.category_positions ? category_id::text) AND ((NEW.category_positions->category_id::text) IS NOT NULL);
      SELECT ranked_get_last_position_in_category(category_id) INTO last_position;
      IF last_position IS NOT NULL THEN
        position := last_position + ranked_step();
      ELSE
        position := 0;
      END IF;
      IF NEW.category_positions IS NULL THEN
        NEW.category_positions := hstore(category_id::text, position::text);
      ELSE
        NEW.category_positions := NEW.category_positions || hstore(category_id::text, position::text);
      END IF;
    END LOOP;
  END IF;

  RETURN NEW;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER ranked_check_product_positions BEFORE INSERT OR UPDATE ON products FOR EACH ROW EXECUTE PROCEDURE ranked_check_product_positions();

-- Makes sure that every position is unique within category by moving duplicated products down
CREATE OR REPLACE FUNCTION ranked_check_product_positions_uniqueness() RETURNS trigger AS $$
DECLARE
  category_id text;
  existing_productd_found integer;
  categories integer[];
  changed_positions hstore;
BEGIN
  IF TG_OP = 'UPDATE' THEN
    -- Get only changed elements of hstore
    SELECT ranked_hstore_diff(OLD.category_positions, NEW.category_positions) INTO changed_positions;
  ELSE
    changed_positions := NEW.category_positions;
  END IF;
  categories := akeys(changed_positions);
  IF array_length(categories, 1) > 0 THEN
    FOREACH category_id IN ARRAY categories LOOP
      SELECT 1 INTO existing_productd_found
        FROM products
        WHERE categories_ids @> ARRAY[category_id::integer] AND (id > NEW.id OR id < NEW.id) AND category_positions->category_id = changed_positions->category_id;
      CONTINUE WHEN existing_productd_found IS NULL;

      UPDATE products
        SET category_positions = category_positions || hstore(category_id, ((category_positions->category_id)::integer + ranked_step())::text)
        WHERE id <> NEW.id AND (category_positions->category_id)::integer >= (changed_positions->category_id::text)::integer;
    END LOOP;
  END IF;

  RETURN NEW;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER ranked_check_product_positions_uniqueness AFTER INSERT OR UPDATE ON products FOR EACH ROW EXECUTE PROCEDURE ranked_check_product_positions_uniqueness();
