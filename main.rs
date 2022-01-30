use std::collections::HashSet;
use std::io::Result;
use std::ops::Range;
use std::{fmt, fs};

fn main() {
    let (rows, one_indices, max_size) = read_files("ones.txt", "stars.txt");

    let mut groups = group(rows, max_size);

    let mut primes = vec![];

    for _ in 0..max_size {
        let (merged, prime_implicants) = merge(groups);
        primes.extend(prime_implicants);
        groups = merged;
    }

    let selected_primes = select_primes(primes, one_indices);

    for row in selected_primes {
        println!("{row}");
    }
}

#[derive(Clone, PartialEq, Eq)]
enum State {
    Zero,
    One,
    Dash,
}

impl fmt::Debug for State {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Zero => write!(f, "0"),
            Self::One => write!(f, "1"),
            Self::Dash => write!(f, "-"),
        }
    }
}

#[derive(Clone, Debug, PartialEq, Eq)]
struct Row {
    group: Range<usize>,
    mappings: Vec<State>,
    indices: HashSet<usize>,
}

impl fmt::Display for Row {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(
            f,
            "{:?} | {:?} | {:?}",
            &self.group, &self.mappings, &self.indices
        )
    }
}

fn read_files(ones_filename: &str, stars_filename: &str) -> (Vec<Row>, Vec<usize>, usize) {
    let mut acc = vec![];

    let (mut ones, _) = read_rows(ones_filename).unwrap();
    let (mut stars, max_size) = read_rows(stars_filename).unwrap();
    let one_indices = ones.iter().flat_map(|row| row.indices.iter().copied()).collect();

    acc.append(&mut ones);
    acc.append(&mut stars);

    (acc, one_indices, max_size)
}

fn read_rows(filename: &str) -> Result<(Vec<Row>, usize)> {
    let contents = fs::read_to_string(filename)?;
    let mut lines = contents.lines();
    let (_, size) = lines.next().unwrap().split_once(" ").unwrap();
    let max_size = size.parse::<usize>().unwrap() + 1;

    let acc: Vec<Row> = lines
        .map(|line| {
            let stripped: String = line.chars().filter(|c| c.is_ascii_digit()).collect();
            let index = usize::from_str_radix(&stripped, 2).unwrap();
            let mappings = stripped
                .chars()
                .map(|c| if c == '1' { State::One } else { State::Zero })
                .collect();
            let group = stripped.chars().filter(|c| *c == '1').count();
            let mut indices = HashSet::new();
            indices.insert(index);
            Row {
                group: group..group,
                mappings,
                indices,
            }
        })
        .collect();

    Ok((acc, max_size))
}

fn group(rows: Vec<Row>, size: usize) -> Vec<Vec<Row>> {
    let mut vec = vec![Vec::new(); size];

    for elem in rows {
        let i = elem.group.start;
        vec[i].push(elem);
    }

    vec
}

fn merge(groups: Vec<Vec<Row>>) -> (Vec<Vec<Row>>, Vec<Row>) {
    let mut acc = vec![Vec::new(); groups.len() - 1];
    let mut used_indices = Vec::new();

    for i in 0..groups.len() - 1 {
        let group1 = &groups[i];
        let group2 = &groups[i + 1];

        for elem1 in group1 {
            for elem2 in group2 {
                let merged_row = merge_rows(elem1, elem2);
                if let Some(merged) = merged_row {
                    acc[i].push(merged);
                    used_indices.push(elem1.indices.to_owned());
                    used_indices.push(elem2.indices.to_owned());
                }
            }
        }
    }

    let mut prime_implicants: Vec<Row> = groups
        .iter()
        .flat_map(|group| {
            group
                .iter()
                .filter(|row| !used_indices.contains(&row.indices))
                .map(|row| row.to_owned())
        })
        .collect();
    prime_implicants.dedup_by(|a, b| a.mappings == b.mappings);

    (acc, prime_implicants)
}

fn merge_rows(elem1: &Row, elem2: &Row) -> Option<Row> {
    let difference = elem1
        .mappings
        .iter()
        .zip(elem2.mappings.iter())
        .filter(|(x, y)| x != y)
        .count();
    if difference != 1 {
        return None;
    }
    let group = elem1.group.start..elem2.group.end;
    let mappings = elem1
        .mappings
        .iter()
        .zip(elem2.mappings.iter())
        .map(|(x, y)| if x != y { State::Dash } else { x.to_owned() })
        .collect();
    let indices =
        elem1
            .indices
            .iter()
            .chain(elem2.indices.iter())
            .fold(HashSet::new(), |mut acc, x| {
                acc.insert(*x);
                acc
            });

    Some(Row {
        group,
        mappings,
        indices,
    })
}

fn select_primes(primes: Vec<Row>, one_indices: Vec<usize>) -> Vec<Row> {
    let mut indices_to_use = one_indices.to_owned();
    let mut primes_left = primes.to_owned();
    let mut primes_to_use = vec![];

    while !indices_to_use.is_empty() {
        primes_left.sort_unstable_by(|a, b| {
            count_common_indices(a, &indices_to_use).cmp(&count_common_indices(b, &indices_to_use))
        });
        if let Some(used_prime) = primes_left.pop() {
            for index in &used_prime.indices {
                indices_to_use.retain(|i| i != index);
            }
            primes_to_use.push(used_prime)
        } else {
            unreachable!("Not enought prime implicants found. This should not happen");
        }
    }

    primes_to_use
}

fn count_common_indices(row: &Row, indices_set: &Vec<usize>) -> usize {
    row.indices
        .iter()
        .filter(|index| indices_set.contains(index))
        .count()
}
