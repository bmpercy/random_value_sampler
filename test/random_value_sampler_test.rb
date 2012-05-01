require 'set'
require 'test/unit'
require 'random_value_sampler'

#
# rough outline of this file:
# * test cases: these just call helper methods to run tests on all of the
#               data cases created below in the setup() method
#   - error inputs
#   - verifying distribution validity
# * helper methods: mostly verify_xxx() methods that are called by the
#                   test cases to compute test results (this is the code
#                   most important to review)
# * setup() method: the method called before each test case is run...to
#                   generate data for testing
#-------------------------------------------------------------------------------
#
# rough outline of tests:
#
# error inputs (invalid distribution specifications, invalid sample requests)
# for each valid input case, run the following tests:
#   for EACH valid input case:
#     confirm # values
#     confirm the array of values returned meet specification
#     confirm probability_of
#       uniform:
#         each value in set/array/range has the same value
#                (and they sum to 1 or within v. small tolerance)
#       non-uniform:
#         each value matches that in the original specification
#       values (just) outside values have probability zero
#-----------------------------------------------------------------------------
class RandomValueSamplerTest < Test::Unit::TestCase
  
  ###############
  # ERROR INPUTS
  ###############

  def test_uniform_error_inputs
    # this line just makes sure that we're running the test on each data
    # case we create in the setup() method. the idea is that if someone adds
    # a new @uniform_xxxxxx case, then they'd add it to the
    # @uniform_error_inputs array, and this assertion would fail...reminding
    # them to add an assert_raises call here for the new data case. (this
    # pattern is repeated throughout the test cases in this file)
    assert_equal(@uniform_error_inputs.length, 4)

    assert_raises(RuntimeError) { RandomValueSampler.new_uniform @uniform_set_error_empty }
    assert_raises(RuntimeError) { RandomValueSampler.new_uniform @uniform_array_error_empty }
    assert_raises(RuntimeError) { RandomValueSampler.new_uniform @uniform_range_error_empty }
    assert_raises(RuntimeError) { RandomValueSampler.new_uniform @uniform_single_error_negative }
  end

  def test_non_uniform_error_inputs
    assert_equal(@nonuniform_error_inputs.length, 6)

    assert_raises(RuntimeError) { RandomValueSampler.new_non_uniform @nonuniform_hash_error_empty }
    assert_raises(RuntimeError) { RandomValueSampler.new_non_uniform @nonuniform_hash_error_negative }
    assert_raises(RuntimeError) { RandomValueSampler.new_non_uniform @nonuniform_hash_error_all_zeros }
    assert_raises(RuntimeError) { RandomValueSampler.new_non_uniform @nonuniform_arrayoftuples_error_empty }
    assert_raises(RuntimeError) { RandomValueSampler.new_non_uniform @nonuniform_arrayoftuples_error_negative }
    assert_raises(RuntimeError) { RandomValueSampler.new_non_uniform @nonuniform_arrayoftuples_error_all_zeros }
  end

  def test_uniform_exception_on_too_many_sample_unique
    # singleton set
    assert_raises(RuntimeError) do 
      rsampler = RandomValueSampler.new_uniform @uniform_set_single_string
      rsampler.sample_unique 2
    end

    # singleton array
    assert_raises(RuntimeError) do 
      rsampler = RandomValueSampler.new_uniform @uniform_array_single_numeric
      rsampler.sample_unique(@uniform_array_single_numeric.length + 1)
    end

    # singleton Range
    assert_raises(RuntimeError) do 
      rsampler = RandomValueSampler.new_uniform @uniform_range_single_exclusive
      rsampler.sample_unique(@uniform_range_single_exclusive.to_a.length + 1)
    end

    # singleton value
    assert_raises(RuntimeError) do 
      rsampler = RandomValueSampler.new_uniform @uniform_single_zero
      rsampler.sample_unique 2
    end

    # size N set
    assert_raises(RuntimeError) do 
      rsampler = RandomValueSampler.new_uniform @uniform_set_10_string
      rsampler.sample_unique(@uniform_set_10_string.length + 1)
    end

    # size N array
    assert_raises(RuntimeError) do 
      rsampler = RandomValueSampler.new_uniform @uniform_array_10_numeric
      rsampler.sample_unique(@uniform_array_10_numeric.length + 1)
    end

    # size N Range inclusive
    assert_raises(RuntimeError) do 
      rsampler = RandomValueSampler.new_uniform @uniform_range_10_inclusive
      rsampler.sample_unique(@uniform_range_10_inclusive.to_a.length + 1)
    end

    # size N Range exclusive
    assert_raises(RuntimeError) do 
      rsampler = RandomValueSampler.new_uniform @uniform_range_10_exclusive
      rsampler.sample_unique(@uniform_range_10_exclusive.to_a.length + 1)
    end

    # scalar defining Range size N
    assert_raises(RuntimeError) do 
      rsampler = RandomValueSampler.new_uniform @uniform_single_nonzero
      rsampler.sample_unique(@uniform_single_nonzero + 2)
    end
  end

  def test_non_uniform_exception_on_too_many_sample_unique
    assert_raises(RuntimeError) do 
      rsampler = RandomValueSampler.new_non_uniform @nonuniform_hash_single_string
      rsampler.sample_unique 2
    end
    assert_raises(RuntimeError) do 
      rsampler = RandomValueSampler.new_non_uniform @nonuniform_hash_10_sum_to_1
      rsampler.sample_unique(@nonuniform_hash_10_sum_to_1.length + 1)
    end
    assert_raises(RuntimeError) do 
      rsampler = RandomValueSampler.new_non_uniform @nonuniform_arrayoftuples_single_string
      rsampler.sample_unique 2
    end
    assert_raises(RuntimeError) do 
      rsampler = RandomValueSampler.new_non_uniform @nonuniform_arrayoftuples_10_sum_to_1
      rsampler.sample_unique(@nonuniform_arrayoftuples_10_sum_gt_1.length + 1)
    end
  end

  def test_negative_num_samples
    assert_raises(RuntimeError) { RandomValueSampler.new_uniform([1,2,3,4]).sample(-1) }
    assert_raises(RuntimeError) { RandomValueSampler.new_uniform([1,2,3,4]).sample_unique(-1) }
  end

  ###################################################
  # VERIFYING VALIDITY, CONSISTENCY OF DISTRIBUTIONS
  ###################################################

  def test_uniform_probability_of
    assert_equal(@uniform_sets.length, 3)
    verify_probability_of(RandomValueSampler.new_uniform(@uniform_set_single_string),
                                           @uniform_set_single_string)
    verify_probability_of(RandomValueSampler.new_uniform(@uniform_set_10_string),
                                           @uniform_set_10_string)
    verify_probability_of(RandomValueSampler.new_uniform(@uniform_set_10_numeric),
                                           @uniform_set_10_numeric)

    assert_equal(@uniform_arrays.length, 3)
    verify_probability_of(RandomValueSampler.new_uniform(@uniform_array_single_numeric),
                                           @uniform_array_single_numeric)
    verify_probability_of(RandomValueSampler.new_uniform(@uniform_array_10_string),
                                           @uniform_array_10_string)
    verify_probability_of(RandomValueSampler.new_uniform(@uniform_array_10_numeric),
                                           @uniform_array_10_numeric)

    assert_equal(@uniform_ranges.length, 4)

    verify_probability_of(RandomValueSampler.new_uniform(@uniform_range_single_exclusive),
                                           @uniform_range_single_exclusive)
    verify_probability_of(RandomValueSampler.new_uniform(@uniform_range_single_inclusive),
                                           @uniform_range_single_inclusive)
    verify_probability_of(RandomValueSampler.new_uniform(@uniform_range_10_exclusive),
                                           @uniform_range_10_exclusive)
    verify_probability_of(RandomValueSampler.new_uniform(@uniform_range_10_inclusive),
                                           @uniform_range_10_inclusive)

    assert_equal(@uniform_singles.length, 2)
    verify_probability_of(RandomValueSampler.new_uniform(@uniform_single_zero),
                                           @uniform_single_zero)
    verify_probability_of(RandomValueSampler.new_uniform(@uniform_single_nonzero),
                                           @uniform_single_nonzero)
  end

  def test_non_uniform_probability_of
    assert_equal(@nonuniform_hashes.length, 4)
    verify_probability_of(RandomValueSampler.new_non_uniform(@nonuniform_hash_single_string),
                                               @nonuniform_hash_single_string)
    verify_probability_of(RandomValueSampler.new_non_uniform(@nonuniform_hash_10_sum_to_1),
                                               @nonuniform_hash_10_sum_to_1)
    verify_probability_of(RandomValueSampler.new_non_uniform(@nonuniform_hash_10_sum_gt_1),
                                               @nonuniform_hash_10_sum_gt_1)
    verify_probability_of(RandomValueSampler.new_non_uniform(@nonuniform_hash_10_sum_lt_1),
                                               @nonuniform_hash_10_sum_lt_1)

    assert_equal(@nonuniform_arrayoftuples.length, 4)
    verify_probability_of(RandomValueSampler.new_non_uniform(@nonuniform_arrayoftuples_single_string),
                                               @nonuniform_arrayoftuples_single_string)
    verify_probability_of(RandomValueSampler.new_non_uniform(@nonuniform_arrayoftuples_10_sum_to_1),
                                               @nonuniform_arrayoftuples_10_sum_to_1)
    verify_probability_of(RandomValueSampler.new_non_uniform(@nonuniform_arrayoftuples_10_sum_gt_1),
                                               @nonuniform_arrayoftuples_10_sum_gt_1)
    verify_probability_of(RandomValueSampler.new_non_uniform(@nonuniform_arrayoftuples_10_sum_lt_1),
                                               @nonuniform_arrayoftuples_10_sum_lt_1)
  end

  def test_uniform_valid_distributions
    assert_equal(@uniform_sets.length, 3)
    verify_distribution(RandomValueSampler.new_uniform(@uniform_set_single_string))
    verify_distribution(RandomValueSampler.new_uniform(@uniform_set_10_string))
    verify_distribution(RandomValueSampler.new_uniform(@uniform_set_10_numeric))


    assert_equal(@uniform_arrays.length, 3)
    verify_distribution(RandomValueSampler.new_uniform(@uniform_array_single_numeric))
    verify_distribution(RandomValueSampler.new_uniform(@uniform_array_10_string))
    verify_distribution(RandomValueSampler.new_uniform(@uniform_array_10_numeric))


    assert_equal(@uniform_ranges.length, 4)

    verify_distribution(RandomValueSampler.new_uniform(@uniform_range_single_exclusive))
    verify_distribution(RandomValueSampler.new_uniform(@uniform_range_single_inclusive))
    verify_distribution(RandomValueSampler.new_uniform(@uniform_range_10_exclusive))
    verify_distribution(RandomValueSampler.new_uniform(@uniform_range_10_inclusive))


    assert_equal(@uniform_singles.length, 2)
    verify_distribution(RandomValueSampler.new_uniform(@uniform_single_zero))
    verify_distribution(RandomValueSampler.new_uniform(@uniform_single_nonzero))
  end

  def test_non_uniform_valid_distributions
    assert_equal(@nonuniform_hashes.length, 4)
    verify_distribution(RandomValueSampler.new_non_uniform(@nonuniform_hash_single_string))
    verify_distribution(RandomValueSampler.new_non_uniform(@nonuniform_hash_10_sum_to_1))
    verify_distribution(RandomValueSampler.new_non_uniform(@nonuniform_hash_10_sum_gt_1))
    verify_distribution(RandomValueSampler.new_non_uniform(@nonuniform_hash_10_sum_lt_1))

    assert_equal(@nonuniform_arrayoftuples.length, 4)
    verify_distribution(RandomValueSampler.new_non_uniform(@nonuniform_arrayoftuples_single_string))
    verify_distribution(RandomValueSampler.new_non_uniform(@nonuniform_arrayoftuples_10_sum_to_1))
    verify_distribution(RandomValueSampler.new_non_uniform(@nonuniform_arrayoftuples_10_sum_gt_1))
    verify_distribution(RandomValueSampler.new_non_uniform(@nonuniform_arrayoftuples_10_sum_lt_1))
  end

  def test_uniform_values_match
    assert_equal(@uniform_sets.length, 3)
    verify_values(RandomValueSampler.new_uniform(@uniform_set_single_string),
                                   @uniform_set_single_string)
    verify_values(RandomValueSampler.new_uniform(@uniform_set_10_string),
                                   @uniform_set_10_string)
    verify_values(RandomValueSampler.new_uniform(@uniform_set_10_numeric),
                                   @uniform_set_10_numeric)

    assert_equal(@uniform_arrays.length, 3)
    verify_values(RandomValueSampler.new_uniform(@uniform_array_single_numeric),
                                   @uniform_array_single_numeric)
    verify_values(RandomValueSampler.new_uniform(@uniform_array_10_string),
                                   @uniform_array_10_string)
    verify_values(RandomValueSampler.new_uniform(@uniform_array_10_numeric),
                                   @uniform_array_10_numeric)

    assert_equal(@uniform_ranges.length, 4)

    verify_values(RandomValueSampler.new_uniform(@uniform_range_single_exclusive),
                                   @uniform_range_single_exclusive)
    verify_values(RandomValueSampler.new_uniform(@uniform_range_single_inclusive),
                                   @uniform_range_single_inclusive)
    verify_values(RandomValueSampler.new_uniform(@uniform_range_10_exclusive),
                                   @uniform_range_10_exclusive)
    verify_values(RandomValueSampler.new_uniform(@uniform_range_10_inclusive),
                                   @uniform_range_10_inclusive)

    assert_equal(@uniform_singles.length, 2)
    verify_values(RandomValueSampler.new_uniform(@uniform_single_zero),
                                   @uniform_single_zero)
    verify_values(RandomValueSampler.new_uniform(@uniform_single_nonzero),
                                   @uniform_single_nonzero)
  end

  def test_non_uniform_values_match
    assert_equal(@nonuniform_hashes.length, 4)
    verify_values(RandomValueSampler.new_non_uniform(@nonuniform_hash_single_string),
                                               @nonuniform_hash_single_string)
    verify_values(RandomValueSampler.new_non_uniform(@nonuniform_hash_10_sum_to_1),
                                               @nonuniform_hash_10_sum_to_1)
    verify_values(RandomValueSampler.new_non_uniform(@nonuniform_hash_10_sum_gt_1),
                                               @nonuniform_hash_10_sum_gt_1)
    verify_values(RandomValueSampler.new_non_uniform(@nonuniform_hash_10_sum_lt_1),
                                               @nonuniform_hash_10_sum_lt_1)

    assert_equal(@nonuniform_arrayoftuples.length, 4)
    verify_values(RandomValueSampler.new_non_uniform(@nonuniform_arrayoftuples_single_string),
                                               @nonuniform_arrayoftuples_single_string)
    verify_values(RandomValueSampler.new_non_uniform(@nonuniform_arrayoftuples_10_sum_to_1),
                                               @nonuniform_arrayoftuples_10_sum_to_1)
    verify_values(RandomValueSampler.new_non_uniform(@nonuniform_arrayoftuples_10_sum_gt_1),
                                               @nonuniform_arrayoftuples_10_sum_gt_1)
    verify_values(RandomValueSampler.new_non_uniform(@nonuniform_arrayoftuples_10_sum_lt_1),
                                               @nonuniform_arrayoftuples_10_sum_lt_1)
  end

  def test_uniform_num_values
    assert_equal(@uniform_sets.length, 3)
    verify_num_values(RandomValueSampler.new_uniform(@uniform_set_single_string))
    verify_num_values(RandomValueSampler.new_uniform(@uniform_set_10_string))
    verify_num_values(RandomValueSampler.new_uniform(@uniform_set_10_numeric))


    assert_equal(@uniform_arrays.length, 3)
    verify_num_values(RandomValueSampler.new_uniform(@uniform_array_single_numeric))
    verify_num_values(RandomValueSampler.new_uniform(@uniform_array_10_string))
    verify_num_values(RandomValueSampler.new_uniform(@uniform_array_10_numeric))


    assert_equal(@uniform_ranges.length, 4)

    verify_num_values(RandomValueSampler.new_uniform(@uniform_range_single_exclusive))
    verify_num_values(RandomValueSampler.new_uniform(@uniform_range_single_inclusive))
    verify_num_values(RandomValueSampler.new_uniform(@uniform_range_10_exclusive))
    verify_num_values(RandomValueSampler.new_uniform(@uniform_range_10_inclusive))


    assert_equal(@uniform_singles.length, 2)
    verify_num_values(RandomValueSampler.new_uniform(@uniform_single_zero))
    verify_num_values(RandomValueSampler.new_uniform(@uniform_single_nonzero))
  end

  def test_non_uniform_num_values
    assert_equal(@nonuniform_hashes.length, 4)
    verify_num_values(RandomValueSampler.new_non_uniform(@nonuniform_hash_single_string))
    verify_num_values(RandomValueSampler.new_non_uniform(@nonuniform_hash_10_sum_to_1))
    verify_num_values(RandomValueSampler.new_non_uniform(@nonuniform_hash_10_sum_gt_1))
    verify_num_values(RandomValueSampler.new_non_uniform(@nonuniform_hash_10_sum_lt_1))

    assert_equal(@nonuniform_arrayoftuples.length, 4)
    verify_num_values(RandomValueSampler.new_non_uniform(@nonuniform_arrayoftuples_single_string))
    verify_num_values(RandomValueSampler.new_non_uniform(@nonuniform_arrayoftuples_10_sum_to_1))
    verify_num_values(RandomValueSampler.new_non_uniform(@nonuniform_arrayoftuples_10_sum_gt_1))
    verify_num_values(RandomValueSampler.new_non_uniform(@nonuniform_arrayoftuples_10_sum_lt_1))
  end

  # sample a bunch of times and make sure that all of the values that come back
  # are in the set of valid raw values
  #-----------------------------------------------------------------------------
  def test_uniform_sample_values_are_valid
    assert_equal(@uniform_sets.length, 3)
    verify_sample_values_are_valid(RandomValueSampler.new_uniform(@uniform_set_single_string),
                                                    @uniform_set_single_string)
    verify_sample_values_are_valid(RandomValueSampler.new_uniform(@uniform_set_10_string),
                                                    @uniform_set_10_string)
    verify_sample_values_are_valid(RandomValueSampler.new_uniform(@uniform_set_10_numeric),
                                                    @uniform_set_10_numeric)

    assert_equal(@uniform_arrays.length, 3)
    verify_sample_values_are_valid(RandomValueSampler.new_uniform(@uniform_array_single_numeric),
                                                    @uniform_array_single_numeric)
    verify_sample_values_are_valid(RandomValueSampler.new_uniform(@uniform_array_10_string),
                                                    @uniform_array_10_string)
    verify_sample_values_are_valid(RandomValueSampler.new_uniform(@uniform_array_10_numeric),
                                                    @uniform_array_10_numeric)

    assert_equal(@uniform_ranges.length, 4)

    verify_sample_values_are_valid(RandomValueSampler.new_uniform(@uniform_range_single_exclusive),
                                                    @uniform_range_single_exclusive)
    verify_sample_values_are_valid(RandomValueSampler.new_uniform(@uniform_range_single_inclusive),
                                                    @uniform_range_single_inclusive)
    verify_sample_values_are_valid(RandomValueSampler.new_uniform(@uniform_range_10_exclusive),
                                                    @uniform_range_10_exclusive)
    verify_sample_values_are_valid(RandomValueSampler.new_uniform(@uniform_range_10_inclusive),
                                                    @uniform_range_10_inclusive)

    assert_equal(@uniform_singles.length, 2)
    verify_sample_values_are_valid(RandomValueSampler.new_uniform(@uniform_single_zero),
                                                    @uniform_single_zero)
    verify_sample_values_are_valid(RandomValueSampler.new_uniform(@uniform_single_nonzero),
                                                    @uniform_single_nonzero)
  end

  def test_non_uniform_sample_values_are_valid
    assert_equal(@nonuniform_hashes.length, 4)
    verify_sample_values_are_valid(RandomValueSampler.new_non_uniform(@nonuniform_hash_single_string),
                                                        @nonuniform_hash_single_string)
    verify_sample_values_are_valid(RandomValueSampler.new_non_uniform(@nonuniform_hash_10_sum_to_1),
                                                        @nonuniform_hash_10_sum_to_1)
    verify_sample_values_are_valid(RandomValueSampler.new_non_uniform(@nonuniform_hash_10_sum_gt_1),
                                                        @nonuniform_hash_10_sum_gt_1)
    verify_sample_values_are_valid(RandomValueSampler.new_non_uniform(@nonuniform_hash_10_sum_lt_1),
                                                        @nonuniform_hash_10_sum_lt_1)

    assert_equal(@nonuniform_arrayoftuples.length, 4)
    verify_sample_values_are_valid(RandomValueSampler.new_non_uniform(@nonuniform_arrayoftuples_single_string),
                                                        @nonuniform_arrayoftuples_single_string)
    verify_sample_values_are_valid(RandomValueSampler.new_non_uniform(@nonuniform_arrayoftuples_10_sum_to_1),
                                                        @nonuniform_arrayoftuples_10_sum_to_1)
    verify_sample_values_are_valid(RandomValueSampler.new_non_uniform(@nonuniform_arrayoftuples_10_sum_gt_1),
                                                        @nonuniform_arrayoftuples_10_sum_gt_1)
    verify_sample_values_are_valid(RandomValueSampler.new_non_uniform(@nonuniform_arrayoftuples_10_sum_lt_1),
                                                        @nonuniform_arrayoftuples_10_sum_lt_1)
  end

  def test_uniform_sample_values_are_valid
    assert_equal(@uniform_sets.length, 3)
    verify_sample_unique_values_are_valid(RandomValueSampler.new_uniform(@uniform_set_single_string),
                                          @uniform_set_single_string)
    verify_sample_unique_values_are_valid(RandomValueSampler.new_uniform(@uniform_set_10_string),
                                          @uniform_set_10_string)
    verify_sample_unique_values_are_valid(RandomValueSampler.new_uniform(@uniform_set_10_numeric),
                                          @uniform_set_10_numeric)

    assert_equal(@uniform_arrays.length, 3)
    verify_sample_unique_values_are_valid(RandomValueSampler.new_uniform(@uniform_array_single_numeric),
                                          @uniform_array_single_numeric)
    verify_sample_unique_values_are_valid(RandomValueSampler.new_uniform(@uniform_array_10_string),
                                          @uniform_array_10_string)
    verify_sample_unique_values_are_valid(RandomValueSampler.new_uniform(@uniform_array_10_numeric),
                                          @uniform_array_10_numeric)

    assert_equal(@uniform_ranges.length, 4)

    verify_sample_unique_values_are_valid(RandomValueSampler.new_uniform(@uniform_range_single_exclusive),
                                          @uniform_range_single_exclusive)
    verify_sample_unique_values_are_valid(RandomValueSampler.new_uniform(@uniform_range_single_inclusive),
                                          @uniform_range_single_inclusive)
    verify_sample_unique_values_are_valid(RandomValueSampler.new_uniform(@uniform_range_10_exclusive),
                                          @uniform_range_10_exclusive)
    verify_sample_unique_values_are_valid(RandomValueSampler.new_uniform(@uniform_range_10_inclusive),
                                          @uniform_range_10_inclusive)

    assert_equal(@uniform_singles.length, 2)
    verify_sample_unique_values_are_valid(RandomValueSampler.new_uniform(@uniform_single_zero),
                                          @uniform_single_zero)
    verify_sample_unique_values_are_valid(RandomValueSampler.new_uniform(@uniform_single_nonzero),
                                          @uniform_single_nonzero)
  end

  def test_non_uniform_sample_values_are_valid
    assert_equal(@nonuniform_hashes.length, 4)
    verify_sample_unique_values_are_valid(RandomValueSampler.new_non_uniform(@nonuniform_hash_single_string),
                                          @nonuniform_hash_single_string)
    verify_sample_unique_values_are_valid(RandomValueSampler.new_non_uniform(@nonuniform_hash_10_sum_to_1),
                                          @nonuniform_hash_10_sum_to_1)
    verify_sample_unique_values_are_valid(RandomValueSampler.new_non_uniform(@nonuniform_hash_10_sum_gt_1),
                                          @nonuniform_hash_10_sum_gt_1)
    verify_sample_unique_values_are_valid(RandomValueSampler.new_non_uniform(@nonuniform_hash_10_sum_lt_1),
                                          @nonuniform_hash_10_sum_lt_1)

    assert_equal(@nonuniform_arrayoftuples.length, 4)
    verify_sample_unique_values_are_valid(RandomValueSampler.new_non_uniform(@nonuniform_arrayoftuples_single_string),
                                          @nonuniform_arrayoftuples_single_string)
    verify_sample_unique_values_are_valid(RandomValueSampler.new_non_uniform(@nonuniform_arrayoftuples_10_sum_to_1),
                                          @nonuniform_arrayoftuples_10_sum_to_1)
    verify_sample_unique_values_are_valid(RandomValueSampler.new_non_uniform(@nonuniform_arrayoftuples_10_sum_gt_1),
                                          @nonuniform_arrayoftuples_10_sum_gt_1)
    verify_sample_unique_values_are_valid(RandomValueSampler.new_non_uniform(@nonuniform_arrayoftuples_10_sum_lt_1),
                                          @nonuniform_arrayoftuples_10_sum_lt_1)
  end

  ####################
  # SAMPLING ACCURACY
  ####################

  def test_uniform_sampling_accuracy
    assert_equal(@uniform_sets.length, 3)
    verify_distribution_accuracy(RandomValueSampler.new_uniform(@uniform_set_single_string),
                                                  @uniform_set_single_string)
    verify_distribution_accuracy(RandomValueSampler.new_uniform(@uniform_set_10_string),
                                                  @uniform_set_10_string)
    verify_distribution_accuracy(RandomValueSampler.new_uniform(@uniform_set_10_numeric),
                                                  @uniform_set_10_numeric)

    assert_equal(@uniform_arrays.length, 3)
    verify_distribution_accuracy(RandomValueSampler.new_uniform(@uniform_array_single_numeric),
                                                  @uniform_array_single_numeric)
    verify_distribution_accuracy(RandomValueSampler.new_uniform(@uniform_array_10_string),
                                                  @uniform_array_10_string)
    verify_distribution_accuracy(RandomValueSampler.new_uniform(@uniform_array_10_numeric),
                                                  @uniform_array_10_numeric)

    assert_equal(@uniform_ranges.length, 4)

    verify_distribution_accuracy(RandomValueSampler.new_uniform(@uniform_range_single_exclusive),
                                                  @uniform_range_single_exclusive)
    verify_distribution_accuracy(RandomValueSampler.new_uniform(@uniform_range_single_inclusive),
                                                  @uniform_range_single_inclusive)
    verify_distribution_accuracy(RandomValueSampler.new_uniform(@uniform_range_10_exclusive),
                                                  @uniform_range_10_exclusive)
    verify_distribution_accuracy(RandomValueSampler.new_uniform(@uniform_range_10_inclusive),
                                                  @uniform_range_10_inclusive)

    verify_distribution_accuracy(RandomValueSampler.new_uniform(@uniform_single_zero),
                                                  @uniform_single_zero)
    # avoiding low probability of single_nonzero...
    verify_distribution_accuracy(RandomValueSampler.new_uniform(9), 9)

  end

  # avoid super low probabilities cause they can easily cause "errors" when
  # assessing distribution accuracy
  def test_non_uniform_sampling_accuracy
    verify_distribution_accuracy(RandomValueSampler.new_non_uniform(@nonuniform_hash_single_string),
                                                      @nonuniform_hash_single_string)
    verify_distribution_accuracy(RandomValueSampler.new_non_uniform( { "one" => 1, "two" => 2, "three" => 3 } ),
                                                       { "one" => 1, "two" => 2, "three" => 3 } )

    verify_distribution_accuracy(RandomValueSampler.new_non_uniform(@nonuniform_arrayoftuples_single_string),
                                                      @nonuniform_arrayoftuples_single_string)
    verify_distribution_accuracy(RandomValueSampler.new_non_uniform( [["heavy", 90], ["light", 10]]),
                                                       [["heavy", 90], ["light", 10]])
  end

  #################
  # HELPER METHODS
  #################

  # verifies that probability_of returns correct results for values in and out
  # of pmf values set (should return 0 if outside set)
  #-----------------------------------------------------------------------------
  def verify_probability_of(rsampler, values)
    vals_and_probs = extract_hash_of_vals_and_probs(values)

    vals_and_probs.each_pair do |val, prob|
      assert_in_delta(prob, rsampler.probability_of(val), 2e-4)
    end
  end

  # verify that a distribution is represented (sum of probability mass is
  # (very, very, very, very close to) 1
  #-----------------------------------------------------------------------------
  def verify_distribution(rsampler)
    total_mass = 0
    rsampler.all_values.each do |val|
      total_mass += rsampler.probability_of(val)
    end

    assert_in_delta(1.0, total_mass, 2e-4)
  end

  # verifies the list of values returned by rsampler are in the values passed
  # in as raw values
  #-----------------------------------------------------------------------------
  def verify_values(rsampler, values)
    raw_val_set = Set.new(extract_array_of_values(values))
    rsampler_val_set = Set.new(rsampler.all_values)

    assert_equal(raw_val_set, rsampler_val_set)
  end

  # verifies the number of values indicated by rsampler. kinda dumb, just checks
  # that it matches the length of the array returned by values (might catch
  # some errors when using Ranges, for example)
  #-----------------------------------------------------------------------------
  def verify_num_values(rsampler)
    assert_equal(rsampler.all_values.length, rsampler.num_values)
  end

  # verify after many iterations that all values returned by sampling are
  # valid values for the rsampler. covers single and multiple samples.
  #-----------------------------------------------------------------------------
  def verify_sample_values_are_valid(rsampler, values)
    vals_and_probs = extract_hash_of_vals_and_probs(values)
    vals_and_probs.delete_if { |val, prob| prob == 0 }

    valid_value_set = Set.new(vals_and_probs.keys)

    (1..1000).each do
      sample = rsampler.sample
      assert(valid_value_set.include?(sample),
             "<#{sample}> is not a valid sample in raw values: <#{values}>")
    end

    (1..1000).each do
      rsampler.sample(10).each do |s|
        assert(valid_value_set.include?(s),
               "<#{s}> is not a valid multi-sample in raw values: <#{values}>")
      end
    end
  end

  # verify after many iterations that all values returned by sampling unique are
  # valid values for the rsampler. covers single and multiple samples.
  #-----------------------------------------------------------------------------
  def verify_sample_unique_values_are_valid(rsampler, values)
    vals_and_probs = extract_hash_of_vals_and_probs(values)
    vals_and_probs.delete_if { |val, prob| prob == 0 }

    valid_value_set = Set.new(vals_and_probs.keys)

    num_multi_samples = [valid_value_set.length, 5].min

    (1..1000).each do
      test_rsampler = Marshal.load(Marshal.dump(rsampler))

      sample = test_rsampler.sample_unique
      assert(valid_value_set.include?(sample),
             "<#{sample}> is not a valid sample in raw values: <#{values.inspect}>")
    end

    (1..1000).each do
      test_rsampler = Marshal.load(Marshal.dump(rsampler))

      if num_multi_samples > 1
        test_rsampler.sample_unique(num_multi_samples).each do |s|
          assert(valid_value_set.include?(s),
                 "<#{s}> is not a valid multi-sample in raw values: <#{values.inspect}>")
        end
      else
        sample = test_rsampler.sample_unique(num_multi_samples)
        assert(valid_value_set.include?(sample),
               "<#{sample}> is not a valid multi-sample in raw values: <#{values.inspect}>")
      end
    end
  end

  # helper to convert whatever original data type we had into an array
  #-----------------------------------------------------------------------------
  def extract_array_of_values(values)
    if values.is_a?(Set) || values.is_a?(Range)
      values = values.to_a
    elsif values.is_a?(Array)
      if values.first.is_a?(Array)
        # don't overwrite object, overwrite reference so that original object remains
        # intact if needed
        values = values.map { |val_and_pm| val_and_pm.first }
      end # otherwise, don't need to do anything; already an array
    elsif values.is_a?(Hash)
      values = values.keys
    else
      values = (0..values).to_a
    end

    values
  end

  # generate a hash of values => probabilities from raw data
  #-----------------------------------------------------------------------------
  def extract_hash_of_vals_and_probs(values)
    vals_and_probs = {}

    # convert the single scalar case to a Range
    if !values.is_a?(Hash) && 
       !values.is_a?(Array) &&
       !values.is_a?(Range) &&
       !values.is_a?(Set)

      values = 0..values
    end
    
    if values.is_a?(Hash)
      vals_and_probs = values
    elsif values.is_a?(Array) && values.first.is_a?(Array)
      vals_and_probs = Hash[*(values.flatten)]
    elsif values.is_a?(Range)
      prob = 1.0 / values.to_a.length.to_f
      values.each { |v| vals_and_probs.merge! v => prob }
    elsif values.is_a?(Set) || values.is_a?(Array)
      prob = 1.0 / values.length.to_f
      values.each { |v| vals_and_probs.merge! v => prob }
    end

    total_mass = 0
    vals_and_probs.each_pair { |val, prob| total_mass += prob }
    vals_and_probs.each_pair do |val, prob|
      vals_and_probs.merge! val => prob / total_mass.to_f
    end

    vals_and_probs
  end

  # sample a bunch from the distribution and compare the result to
  # the original distribution. try sampling many times and making sure
  # that the resulting frequencies are accurate within 30% ???
  # this is VERY approximate, and is really only able to catch
  # egregious errors...and is a little susceptible to noise on small
  # probabilities.
  # 
  # NOTE: this only works if theere are no duplicate values in the
  # distribution, as this method uses a hash to store counts of samples.
  #-----------------------------------------------------------------------------
  def verify_distribution_accuracy(rsampler, values)
    vals_and_probs = extract_hash_of_vals_and_probs(values)
    
    val_counts = {}
    vals_and_probs.keys.each { |val, prob| val_counts.merge! val => 0 }

    # sample a bunch and count frequency of each value
    num_samples = 50000
    rsampler.sample(num_samples).each { |v| val_counts[v] = val_counts[v] + 1 }

    # convert counts to probabilities
    val_counts.each_pair do |val, count|
      val_counts.merge! val => (count.to_f / num_samples.to_f)
    end

    vals_and_probs.each_pair do |val, true_prob|
      assert_in_delta( (true_prob - val_counts[val]) / true_prob,
                       0.0,
                       0.1,
                       "observed sample frequency (<#{val_counts[val]}>) of " +
                       "<#{val}> doesn't appear to match true distribution " +
                       "(prob of <#{true_prob}>. It's possible that this was " +
                       "noise, so try again before assuming something's wrong")
    end

  end

  # cases to test:
  # -------------
  # 
  # uniform
  #   valid inputs
  #     Set
  #     array
  #     Range inclusive
  #     Range exclusive
  #     scalar
  #     edge cases
  #       single value
  #         set
  #         array
  #         1..1
  #         1...2
  #         0   (converted to 0..0)
  #   invalid inputs
  #     empty set
  #     empty array
  #     nil
  #     string
  # NOTE: though it should work fine in the class itself, to avoid having to handle
  # lots of cases in the test code, we're not using arrays as the possible values
  # in the distribution (makes it hard to distinguish between the array of tuples
  # (non-uniform) and the array of values (uniform) cases.
  #
  # non-uniform
  #   valid inputs
  #     hash
  #     array of arrays
  #     edge case
  #       1 entry
  #     for EACH case above:
  #     
  #   invalid inputs
  #     empty hash
  #     empty array
  #     array of scalars
  #     negative frequency count
  #       hash
  #       array
  #     non-empty but all counts == 0
  #       hash
  #       array

  # create a set of test data to play with for each test
  #
  # naming conventions:
  #   <pmftype>_<datatype>_<case>
  # 
  #  where:
  #   pmftype is "uniform" or "nonuniform"
  #   datatype is "set", "array", "range", "scalar", "arrayoftuples", or "hash" 
  #   
  #   where: case is one of the following:
  #     error_<condition>
  #     single_<type>
  #     10_<type>
  # 
  #     where:
  #       condition is a description of the error case (e.g. "empty", "allzero"...)
  #       type is "numeric", "string" or "mixed"
  #----------------------------------------------------------------------------- 
  def setup
    ##########
    # UNIFORM
    ##########
    array_of_ten_string = ['a','b','c','d','e','f','g','h','i','j']

    # valid inputs

    @uniform_set_single_string = Set.new(["one"])
    @uniform_set_10_string = Set.new(array_of_ten_string)
    @uniform_set_10_numeric = Set.new(3..12)

    @uniform_array_single_numeric = [22]
    @uniform_array_10_string = array_of_ten_string
    @uniform_array_10_numeric = (101...111).to_a

    @uniform_range_single_exclusive = 1...2
    @uniform_range_single_inclusive = 2..2
    @uniform_range_10_exclusive = 1...11
    @uniform_range_10_inclusive = -2..7

    @uniform_single_zero = 0
    @uniform_single_nonzero = 22

    @uniform_sets = [ 
                     @uniform_set_single_string,
                     @uniform_set_10_string,
                     @uniform_set_10_numeric
                    ]
    @uniform_arrays = [
                       @uniform_array_single_numeric,
                       @uniform_array_10_string,
                       @uniform_array_10_numeric
                      ]
    @uniform_ranges = [
                       @uniform_range_single_exclusive,
                       @uniform_range_single_inclusive,
                       @uniform_range_10_exclusive,
                       @uniform_range_10_inclusive
                      ]
    @uniform_singles = [
                        @uniform_single_zero,
                        @uniform_single_nonzero
                       ]

    # error inputs

    @uniform_set_error_empty = Set.new
    @uniform_array_error_empty = []
    @uniform_range_error_empty = 0..-1
    @uniform_single_error_negative = -1

    @uniform_error_inputs = [
                             @uniform_set_error_empty,
                             @uniform_array_error_empty,
                             @uniform_range_error_empty,
                             @uniform_single_error_negative
                            ]

    ##############
    # NON-UNIFORM
    ##############

    hash_10_sum_to_1 = {}
    (-9..-1).each { |exp| hash_10_sum_to_1.merge! exp => 2**exp }
    hash_10_sum_to_1.merge! "the end" => 2**-9

    hash_10_sum_gt_1 = hash_10_sum_to_1.clone
    hash_10_sum_gt_1.each_pair { |k,v| hash_10_sum_gt_1[k] = v*10 }

    hash_10_sum_lt_1 = hash_10_sum_to_1.clone
    hash_10_sum_lt_1.each_pair { |k,v| hash_10_sum_gt_1[k] = v/10 }

    @nonuniform_hash_single_string = { "one_and_only" => 13 }
    @nonuniform_hash_10_sum_to_1 = hash_10_sum_to_1
    @nonuniform_hash_10_sum_gt_1 = hash_10_sum_gt_1
    @nonuniform_hash_10_sum_lt_1 = hash_10_sum_lt_1

    @nonuniform_arrayoftuples_single_string = { "one_and_only" => 13 }.to_a
    @nonuniform_arrayoftuples_10_sum_to_1 = hash_10_sum_to_1.to_a
    @nonuniform_arrayoftuples_10_sum_gt_1 = hash_10_sum_gt_1.to_a
    @nonuniform_arrayoftuples_10_sum_lt_1 = hash_10_sum_lt_1.to_a

    @nonuniform_hashes = [
                          @nonuniform_hash_single_string,
                          @nonuniform_hash_10_sum_to_1,
                          @nonuniform_hash_10_sum_gt_1,
                          @nonuniform_hash_10_sum_lt_1
                         ]

    @nonuniform_arrayoftuples = [
                                 @nonuniform_arrayoftuples_single_string,
                                 @nonuniform_arrayoftuples_10_sum_to_1,
                                 @nonuniform_arrayoftuples_10_sum_gt_1,
                                 @nonuniform_arrayoftuples_10_sum_lt_1
                                ]

    # error inputs

    @nonuniform_hash_error_empty = {}
    @nonuniform_hash_error_negative = { "negative" => -1 }
    @nonuniform_hash_error_all_zeros = { :one => 0, :two => 0, :three => 0 }

    @nonuniform_arrayoftuples_error_empty = {}.to_a
    @nonuniform_arrayoftuples_error_negative = { "negative" => -1 }.to_a
    @nonuniform_arrayoftuples_error_all_zeros = { :one => 0, :two => 0, :three => 0 }.to_a

    @nonuniform_error_inputs = [
                                @nonuniform_hash_error_empty,
                                @nonuniform_hash_error_negative,
                                @nonuniform_hash_error_all_zeros,
                                @nonuniform_arrayoftuples_error_empty,
                                @nonuniform_arrayoftuples_error_negative,
                                @nonuniform_arrayoftuples_error_all_zeros
                               ]
  end

end
