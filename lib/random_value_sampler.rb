require File.join(File.dirname(File.expand_path(__FILE__)), 'random_value_sampler/version')

# simple class for generating and sampling from a probability distribution,
# including implementation of sampling from uniform and arbitrary distributions
# on discrete random variables, by passing in an object that represents
# the probability mass function (PMF) for a distribution.
#
# the PMF can be computed from non-distributions (e.g. frequency counts)
# provided in the form of a hash or array of tuples (that is, an array of
# [arrays of length 2]).
# 
# the values of the random variable can be anything, but the frequencies/
# probabilities must be numeric (or convertible to numeric via .to_f())
#
# note that if a value is repeated multiple times in the frequency count/
# distribution passed in, then the frequency mass is simply summed for
# each occurrence of the value. this will allow you to pass in a large array
# of each occurrence of values in the data set. For example, you could pass
# in an array of tuples where each value is a word in a document and every
# value is set to 1 so that you don't actually have to do the word
# counting yourself.
#
# (if you would like to ensure uniqueness, provide Set as the values variable
#  to the new_uniform() factory method)
#
# PMFscan also be created for uniform distributions by simply specifying the
# values the random variable may take on.
#
# you can also create a RandomValueSampler directly, by passing in an object
# that represents the distribution/probability function you'd like to sample
# from. (this allows for continous random variables as well). the object
# simply needs to respond_to? the folowing methods:
#   - sample_from_distribution -> single value sampled from distribution
#         and then permanently remove the value from the distribution
#   - all_values -> Array of all values
#   - num_values -> integer giving the number of possible values
#   - probability_of(val) -> probability (numeric type)
#     --> since this library was created for discrete random variables, this
#         method was included. just create a dummy implementation (maybe return
#         0, to be 'correct') if your distribution is a continuous variable?
# NOTE: if the object also responds to sample_from_distribution_and_remove(),
# the sample_unique() method will likely run faster.
#-------------------------------------------------------------------------------
class RandomValueSampler
  # instantiate RandomValueSampler given a probability_function object. the
  # object must respond to:
  #   - sample_from_distribution -> single value sampled from distribution
  #   - all_values -> Array of all values
  #   - num_values -> integer giving the number of possible values
  #   - probability_of(val) -> probability (numeric type)
  #
  # if you're creating a discrete random variable with uniform or arbitrary
  # PMF, recommend using the new_uniform() or new_non_uniform() methods instead
  #
  # use this if you have a continuous random variable or want to create your
  # own standard PMF (e.g. geometric, bernoulli, binomial...)
  #-----------------------------------------------------------------------------
  def initialize(pmf)
    unless pmf.respond_to?(:sample_from_distribution) &&
           pmf.respond_to?(:all_values) &&
           pmf.respond_to?(:num_values) &&
           pmf.respond_to?(:probability_of)

      raise "Received non-pmf-like object of type '#{pmf.class.name}'"
    end

    @pmf = pmf
  end

  # create a sampler for a uniform distribution given an array of values, a
  # range of values, or a scalar defining a range
  #
  # cases:
  #  - Set of values: each member will receive equal probability
  #  - Array of values: the array can contain a sequence of any objects and
  #    each will be assigned equal probability
  #  - Range object (e.g. 3..18): distribution will be uniform over the
  #    entire range specified (including first and last in the range)
  #  - scalar: the distribution will be uniform over [0, value] (0 and
  #            value will be included in the distribution)
  #
  # note that if a value is repeated multiple times in the frequency count/
  # distribution passed in, then the frequency mass is simply summed for
  # each occurrence of the value. this will allow you to pass in a large array
  # of each occurrence of values in the data set. this could be done to
  # 'optimize' a distribution that is very nearly uniform....also see comments
  # on this class.
  #-----------------------------------------------------------------------------
  def self.new_uniform(values)
    self.new(UniformPmf.new(values))
  end

  
  # create a sampler for a non-uniform distribution given either a hash or an
  # array of tuples specifying the probability mass (or frequency count) for
  # each value. if the frequency counts don't represent a proper distribution,
  # they will be normalized to form a distribution, but the original values
  # will be left untouched.
  #
  # if you happen to have a uniform distribution (and know it), it is
  # recommended that you use new_uniform() as it will be much more efficient
  # 
  # cases:
  #  - Hash: keys == the random variable values; values == the frequency count/
  #          probability mass assigned to that value
  #  - Array: each element in the array is a two-element array.
  #           first == the random variable value; last == the frequency count/
  #           probability mass assigned to that value
  #-----------------------------------------------------------------------------
  def self.new_non_uniform(values_and_counts)
    self.new(NonUniformPmf.new(values_and_counts))
  end


  # returns n (pseudo-) independent samples from the pmf defined by this
  # object, returning the result in an array. n is optional, default is 1
  # duplicates ARE allowed; if you want all samples to be unique, then call
  # sample_unique.
  #
  # this performs "sampling with replacement"
  #-----------------------------------------------------------------------------
  def sample(n = 1)
    raise "n must be 0 or greater to sample" if n <= 0

    samples = []

    (1..n).each do
      samples << pmf.sample_from_distribution
    end

    samples.length == 1 ? samples.first : samples
  end


  # returns n (pseudo-) independent samples from the pmf defined by this
  # object, with the condition that each value can only be represented once
  # in the result (no duplicates). n is optional, default is 1.
  #
  # probably only makes sense to call this method if you're sampling a
  # discrete (vs. continuous) random variable, in which case the probability of
  # getting the same value twice is in theory zero, but in practice should be
  # exceedingly low (unless you're testing the precision of the data type you're
  # using.
  #
  # this performs "sampling without replacement"
  #-----------------------------------------------------------------------------
  def sample_unique(n = 1)
    raise "n must be 0 or greater to sample_unique" if n < 0

    samples = nil

    # take care of edge cases: where they ask for more samples than there are
    # entries in the distribution
    if n > pmf.num_values
      samples = pmf.all_values.uniq
    else
      # use a set in case the calling code added multiple copies of the same
      # object into distribution
      samples = Set.new
      while samples.length < n && pmf.num_values > 0
        if pmf.respond_to?(:sample_from_distribution_and_remove)
          samples << pmf.sample_from_distribution_and_remove
        else
          samples << pmf.sample_from_distribution
        end
      end
    end

    return (n == 1 && samples.size == 1) ? samples.first : samples.to_a
  end


  # some pass-through methods...

  # returns probability of a given value
  #-----------------------------------------------------------------------------
  def probability_of(val)
    pmf.probability_of(val)
  end

  # returns array of all possible values for the rv. be careful calling this
  # on pmfs with lots of values...a very large array will be created...which
  # wouldn't happen if you just use the sampling methods....
  #-----------------------------------------------------------------------------
  def all_values
    pmf.all_values
  end

  # returns the number of possible values for the rv
  #-----------------------------------------------------------------------------
  def num_values
    pmf.num_values
  end


  # streamlines the case of uniform distributions where we can be a little
  # more efficient
  #-----------------------------------------------------------------------------
  class UniformPmf

    attr_reader :num_values, :values

    # create a uniform pmf given an array of values, a range of values, or a 
    # scalar defining a range
    #
    # cases:
    #  - Set of values
    #  - Array of values: the array can contain a sequence of any objects and
    #    each will be assigned equal probability. NOTE: does NOT ensure that
    #    duplicates are removed, so if values are entered more than once in
    #    the array, the distribution will likely no longer be uniform.
    #  - Range object (e.g. 3..18): distribution will be uniform over the
    #    entire range specified...note that the range must support the minus
    #    operator (so most appropriate for ranges defined with numeric
    #    endpoints--e.g. the Xs example in the Range class wouldn't work)
    #  - scalar: the distribution will be uniform over [0, value] (0 and
    #            value will be included in the distribution)
    #---------------------------------------------------------------------------
    def initialize(vals)
      if !vals.is_a?(Set) && !vals.is_a?(Array) && !vals.is_a?(Range)
        val = vals.to_i
        if val < 0
          raise "Scalar input must be at least 0 to create distribution"
        end
        vals = 0..val
      end

      if vals.is_a? Set
        if vals.length == 0
          raise "Cannot create uniform distribution from empty set"
        end
        @num_values = vals.length
        @values = vals.to_a
      elsif vals.is_a? Array
        if vals.length == 0
          raise "Cannot create uniform distribution from empty array"
        end

        @num_values = vals.length
        @values = vals.clone
      else # (Range)
        @num_values = vals.last - vals.first + (vals.exclude_end? ? 0 : 1)
        @values = vals

        if @num_values <= 0
          raise "Cannot create distribution from empty range: #{vals.inspect}"
        end
      end
    end

    # sample from the distribution, returning the sampled value
    #---------------------------------------------------------------------------
    def sample_from_distribution
      index = (rand() * @num_values).floor
      if @values.is_a? Array
        sample = @values[index]
      else
        sample = @values.first + index
      end
    end


    # sample from the distribution, and then remove that value from the 
    # distribution forever. note that this may make a distribution defined
    # by a range perform worse.
    #-----------------------------------------------------------------------------
    def sample_from_distribution_and_remove
      sample = sample_from_distribution

      if @values.is_a?(Range)
        @values = @values.to_a
      end

      @values.delete(sample)
      @num_values = @values.length
      @probability = nil # force recalculation of probability next time

      return sample
    end


    # returns all possible values for the pmf
    #---------------------------------------------------------------------------
    def all_values
      values.to_a
    end


    # returns the probability of the given value (including zero if the value
    # is not a possible value for the random variable)
    #---------------------------------------------------------------------------
    def probability_of(value)
      @probability ||= 1.0 / @num_values.to_f
    end

  end # end UniformPmf inner class
  

  # class to handle the non-uniform pmf case, optimized to take advantage of
  # the equal proability mass assigned to each value
  #-----------------------------------------------------------------------------
  class NonUniformPmf
    # initialize the non-uniform distribution from frequency counts. will
    # normalize the frequecy counts to a distribution (yes, even if a
    # distribution is passed in as argument--yes, could be optimized to allow
    # caller to specify that it is a distribution, but that could create 'bugs'
    # in this code, and it's probably not _THAT_ expensive compared to sampling
    # from the distribution).
    # 
    # arguments:
    #  - frequency_counts: hash, or array of two-element arrays of random
    #                      variable values and the associated frequency for each
    #---------------------------------------------------------------------------
    def initialize(frequency_counts)
      @total_mass = 0.0

      if frequency_counts.nil? ||
          (!frequency_counts.is_a?(Hash) && !frequency_counts.is_a?(Array)) ||
          frequency_counts.empty?

        raise "no (or empty) frequency counts or distribution was specified"
      end

      if frequency_counts.is_a? Hash
        populate_distribution_from_hash frequency_counts
      elsif frequency_counts.is_a? Array
        populate_distribution_from_array frequency_counts
      end

      if @total_mass <= 0.0
        raise("Received invalid frequency counts where total mass sums to " +
              "#{@total_mass}")
      end
    end


    # returns probability of given value
    #---------------------------------------------------------------------------
    def probability_of(val)
      distribution_lookup[val] / @total_mass
    end


    # take one sample from the distribution
    #---------------------------------------------------------------------------
    def sample_from_distribution
      sampled_mass = rand() * @total_mass
      summed_mass = 0
      val = nil

      distribution.each do |val_and_prob|
        val = val_and_prob.first
        prob = val_and_prob.last

        summed_mass += prob

        if summed_mass > sampled_mass
          break
        end
      end

      val
    end


    # take one sample from the distribution and remove from distribution forever
    #-----------------------------------------------------------------------------
    def sample_from_distribution_and_remove
      sample = sample_from_distribution
      mass = distribution_lookup[sample]

      @total_mass -= mass
      distribution_lookup.delete(sample)
      distribution.delete_if { |d| d.first == sample }

      sample
    end


    # return the number of possible values
    #---------------------------------------------------------------------------
    def num_values
      distribution.length
    end


    # returns an array of all possible random variable values
    #---------------------------------------------------------------------------
    def all_values
      # the rv values are the keys in the lookup hash
      distribution_lookup.keys
    end

    protected

    attr_reader :distribution, :distribution_lookup

    # populates the distribution from the frequency counts in Hash form
    #---------------------------------------------------------------------------
    def populate_distribution_from_hash(frequency_counts)
      @distribution_lookup = {}

      frequency_counts.each_pair do |val, freq|
        freq = freq.to_f
        raise "Invalid negative frequency (#{freq}) for value #{val}" if freq < 0

        @total_mass += freq
        if @distribution_lookup.has_key? val
          @distribution_lookup[val] += freq
        else
          @distribution_lookup[val] = freq
        end
      end

      populate_distribution_array
    end


    # populates the distribution from the frequency counts in Array form
    #---------------------------------------------------------------------------
    def populate_distribution_from_array(frequency_counts)
      @distribution_lookup = {}

      frequency_counts.each do |val_freq|
        val = val_freq.first
        freq = val_freq.last.to_f
        raise "Invalid negative frequency (#{freq}) for value #{val}" if freq < 0

        @total_mass += freq
        if @distribution_lookup.has_key? val
          @distribution_lookup[val] += freq
        else
          @distribution_lookup[val] = freq
        end
      end

      populate_distribution_array
    end

    # populates the distribution array
    #---------------------------------------------------------------------------
    def populate_distribution_array
      @distribution = []

      @distribution_lookup.each_pair do |val, freq|
        next if freq == 0
        @distribution << [val, freq]
      end
    end

  end # end NonUniformPmf inner class

  protected

  # the underlying pmf object
  attr_reader :pmf

end # end random value sampler class
