defmodule DoubleCheck do
  @moduledoc """
  A module for distributing assignments to assignees.

  Originally designed to distribute exams to graders, the goals were these:
  * Have every exam graded twice, by two different graders.
  * Have every grader grade at least one exam in common with every other grader,
    so that any bias by a particular grader can be accounted for.
  * Allow graders to be assigned multiple batches of tests to grade,
    where the number of batches can differ between graders, and size of each batch is roughly equal.

  The way it works is this:
  1. Generate a list of unique pairs of graders
  2. Go through the list of exams, and assign each next exam to both graders in a pair
  3. Assign each remaing exam twice to the next two graders, who each have at least one batch with current smallest batch size of all batches.

  ## Example

  Say you have graders A, B, and C.
  The list of unique pairs for these three would be

  ```elixir
    {'A', 'B'}, {'A', 'C'}, {'B', 'C'}
  ```

  Now lets say grader B is only part time, so they are given one batch of exams to grade,
  whereas graders A, and C are assigned two batches each.

  Grader      | Assigned exams
  :---------- | -------------:
  A (batch 1) |             []
  A (batch 2) |             []
  B           |             []
  C (batch 1) |             []
  C (batch 2) |             []

  Next, lets say there are six exams that need grading.
  ```elixir
    [1,2,3,4,5,6]
  ```


  We first iterate trough the list of unique pairs,
  popping exams to be assigned off the list,
  and assigning them to both graders in the pairs,
  and to the next batch with the least assignments.
  > ```elixir
  > [{'A', 'B'}, ...
  > [1,2,3,4,5,6]
  >  ^
  > ```

  Grader      | Assigned exams
  :---------- | -------------:
  A (batch 1) |            [1]
  A (batch 2) |             []
  B           |            [1]
  C (batch 1) |             []
  C (batch 2) |             []



  > ```elixir
  > ..., {'A', 'C'}, ...
  > [1,2,3,4,5,6]
  >    ^
  > ```

  Grader      | Assigned exams
  :---------- | -------------:
  A (batch 1) |            [1]
  A (batch 2) |            [2]
  B           |            [1]
  C (batch 1) |            [2]
  C (batch 2) |             []



  > ```elixir
  > ..., {'B', 'C'}]
  > [1,2,3,4,5,6]
  >      ^
  > ```

  Grader      | Assigned exams
  :---------- | -------------:
  A (batch 1) |            [1]
  A (batch 2) |            [2]
  B           |         [1, 3]
  C (batch 1) |            [2]
  C (batch 2) |            [3]



  Finally, we finisih iterating across the list of exams,
  and assign each remaining exam to the next to two graders
  who have a batch with a current size less than or equal to every other batch.

  > ```elixir
  >   # Graders A(batch 1), and C(batch 1)
  >   [1,2,3,4,5,6]
  >          ^
  > ```

  Grader      | Assigned exams
  :---------- | -------------:
  A (batch 1) |         [1, 4]
  A (batch 2) |            [2]
  B           |         [1, 3]
  C (batch 1) |         [2, 4]
  C (batch 2) |            [3]



  > ```elixir
  >   # Graders A(batch 2), and C(batch 2)
  >   [1,2,3,4,5,6]
  >            ^
  > ```

  Grader      | Assigned exams
  :---------- | -------------:
  A (batch 1) |         [1, 4]
  A (batch 2) |         [2, 5]
  B           |         [1, 3]
  C (batch 1) |         [2, 4]
  C (batch 2) |         [3, 5]



  > ```elixir
  >   # Graders A(batch 1), and B
  >   [1,2,3,4,5,6]
  >              ^
  > ```

  Grader      | Assigned exams
  :---------- | -------------:
  A (batch 1) |      [1, 4, 6]
  A (batch 2) |         [2, 5]
  B           |      [1, 3, 6]
  C (batch 1) |         [2, 4]
  C (batch 2) |         [3, 5]



  Once every exam has been assigned to a grader, the program return a list of maps, with the grader and thier assignments:

  ```elixir
  [
    %{grader: "A", assignments: [1, 2, 4, 5, 6]},
    %{grader: "B", assignments: [1, 3, 6]},
    %{grader: "C", assignments: [2, 3, 4, 5]}
  ]
  ```


  """



  @doc """
  Generates a list of tuples, reperesnting each unique pair from a given list of objects.

  ## Examples

      iex> DoubleCheck.get_pairs(['A', 'B', 'C'])
      [{'A', 'B'}, {'A', 'C'}, {'B', 'C'}]

  """
  def get_pairs(list) do
    r = Enum.reduce(list, {1, list, []}, fn
      x, acc ->
        {i, sublist, pairs} = acc
        tail = sublist |> Enum.drop(1)
        new_pairs = Enum.reduce(tail, [], fn
          y, pair_acc ->
            pair_acc ++ [{x, y}]
        end)
        {i+1, tail, pairs ++ new_pairs}
      end)
    {_count, _list, pairs} = r
    pairs
  end

end
