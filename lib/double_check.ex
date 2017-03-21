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
