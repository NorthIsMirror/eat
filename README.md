# Eat food calculator

Example use: type '(100g millet + 100g egg)*2.5 + 100g ham' to see various data on the food

Uses ReadLine and RecDescent. It's like WolframAlpha, allows the same complex queries (and even more complex ones, the above will not work in WA), except that it works with weights.

# Example

    # ./eat.pl
    Processing buckwheat.yml
    Processing egg.yml
    Processing ham.yml
    Processing raw-lentils.yml
    Processing raw-millet.yml
    Processing sunflower.yml
    Using Term::ReadLine::Perl
    Enter query: (100g millet + 100g egg)*2.5 + 100g ham
    Computing data for: 250g Millet, 250g Egg, 100g Ham
    ================================
    | Vitamin         |  Percent   |
    +-----------------+------------+
    | A               |     30     |
    | C               |     2      |
    | E               |     16     |
    | beta tocophreol |     0      |
    | gamma           |     0      |
    | delta           |     0      |
    | D               |    47.5    |
    | K               |     0      |
    | thiamin B1      |   113.5    |
    | riboflavin B2   |    116     |
    | niacin B3       |     78     |
    | B6              |     81     |
    | biotin B7       |     0      |
    | folate B9       |    78.5    |
    | folic acid B9   |     0      |
    | B12             |     45     |
    | panto acid B5   |     59     |
    ================================
    ================================
    | Mineral         |  Percent   |
    +-----------------+------------+
    | calcium         |    18.5    |
    | iron            |    66.5    |
    | magnesium       |     84     |
    | phosphorus      |   138.5    |
    | potassium       |     35     |
    | sodium          |     70     |
    | zinc            |    58.5    |
    | copper          |   109.5    |
    ================================
    ================================
    | Amino acid      |   Amount   |
    +-----------------+------------+
    | proteins        |    74.5    |
    | tryptophan      |   868.5    |
    | threonine       |   2934.5   |
    | isoleucine      |   3455.5   |
    | leucine         |    7.3     |
    | lysine          |   2668.9   |
    | methionine      |    1875    |
    | cystine         |    1383    |
    | phenylalanine   |    3694    |
    | tyrosine        |   2567.5   |
    | valine          |    4164    |
    | arginine        |    2841    |
    | histidine       |   1915.5   |
    | alanine         |  2641.475  |
    | aspartic acid   |   1819.5   |
    | glutamic acid   |    12.4    |
    | glycine         |   2566.5   |
    | proline         |    4112    |
    | serine          |   4521.5   |
    | hydroxyproline  |     40     |
    ================================

