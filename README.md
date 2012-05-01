# RandomValueSampler

Class to allow sampling from very, very simple probability mass functions
(uniform and arbitrary non-uniform). Values can be any object; 
for uniform distributions, a Range can be used to specify a range of
discrete values.

To specify a uniform distribution, only the values need to be specified, and
can be:
  - an Array of values (it is assumed the values are distinct, but you may
    insert duplicates if you know what you're doing and realize you're probably
    no longer dealing with a truly uniform distribution anymore (but this could
    be used to "cheat" to generate distributions that are 'nearly' uniform where
    probability mass is quantized (e.g. a 1/3, 2/3 distribution). This may
    prove to be a more efficient implementation in such cases as the non-uniform
    pmf is more computationally demanding).
  - a ruby Range object; RandomValueSampler honors the inclusion/exclusion of last/end
    of the Range (as defined by exclude_end? method). the Range must be of
    numeric type unless you REALLY know what you're doing (e.g. the Xs class
    example in the Range rdoc won't work).
  - a single numeric type specifying an upper bound (zero is assumed as 
    lower bound--both zero and upper bound are included in distribution)

To specify a non-uniform distribution, the values and probability mass
must be specified. It is not necessary for the probability mass to
represent a true probability distribution (needn't sum to 1), as the class
will normalize accordingly. The pmf may be specified as a Hash or an Array:
  - Hash, where the hash keys are the possible values the random variable
    can take on; the hash values are the 'frequency counts' or non-normalized
    probability mass
  - Array, each element of which is a two-element array. each two element
    array's first element is the value; the last element is the frequency
    count for that value

## Installation

Add this line to your application's Gemfile:

    gem 'random_value_sampler'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install random_value_sampler

## Usage

require 'random_value_sampler'

uniform
-------

# generate a uniform pmf over [1,5]
a = RandomValueSampler.new_uniform([1,2,3,4,5])

# generate a uniform pmf over some words
a = RandomValueSampler.new_uniform(["one", "two", "buckle", "my", "shoe"])

# generate a 'quantized' pmf by using duplicate entries
a = RandomValueSampler.new_uniform([1, 2, 2, 3, 3, 3])
a = RandomValueSampler.new_uniform(["the", "the", "a", "the", "and", "zyzzyva"])

# generate a uniform pmf over [1,5] using a Range
a = RandomValueSampler.new_uniform(1..5)
a = RandomValueSampler.new_uniform(1...6)

# generate a uniform pmf over [0,5] by specifying upper limit
a = RandomValueSampler.new_uniform(5)

non-uniform
-----------

# generate a non-uniform pmf using the Hash form:

# values are 5 and 10, with probability 0.4 and 0.6, respectively
a = RandomValueSampler.new_non_uniform( { 5 => 20, 10 => 30 } )

# values are "probable", "possible" and "not likely" with probability
# 0.75, 0.20 and 0.05, respectively.
a = RandomValueSampler.new_non_uniform( { "probable" => 75,
                            "possible" => 20, 
                            "not likely" => 5 } )

# generate a non-uniform pmf using the Array form (same examples as above)
a = RandomValueSampler.new_non_uniform( [ [5,20], [10,30] )
a = RandomValueSampler.new_non_uniform( [ ["probable",75],
                            ["possible" => 20], 
                            ["not likely" => 5 ] ] )

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Write new tests and test:
   bundle exec rake test
   (NOTE: if you add new test files, please clean up the test rake test...it's a hack right now)
4. Commit your changes (`git commit -am 'Added some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create new Pull Request
