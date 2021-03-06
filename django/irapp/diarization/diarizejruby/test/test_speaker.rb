# diarize-jruby
# 
# Copyright (c) 2013 British Broadcasting Corporation
# 
# Licensed under the GNU Affero General Public License version 3 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# http://www.gnu.org/licenses/agpl
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'helper'
require 'tempfile'

class TestSpeaker < Test::Unit::TestCase

  def test_detection_threshold
    Diarize::Speaker.detection_threshold = 0.1
    assert_equal 0.1, Diarize::Speaker.detection_threshold
  end

  def test_find_or_create_gives_same_object_if_called_with_same_id
    speaker1 = Diarize::Speaker.find_or_create('S0', 'M')
    speaker2 = Diarize::Speaker.find_or_create('S0', 'M')
    assert_equal speaker2.object_id, speaker1.object_id
  end

  def test_initialize
    speaker = Diarize::Speaker.new('uri', 'm')
    assert_equal speaker.uri, 'uri'
    assert_equal speaker.gender, 'm'
  end

  def test_initialize_ubm
    speaker = Diarize::Speaker.ubm
    assert_equal speaker.gender, nil
    assert_equal speaker.uri, nil
    assert_equal speaker.model.name, 'MSMTFSFT' # UBM GMM
  end

  def test_initialize_with_model
    model_file = File.join(File.dirname(__FILE__), 'data', 'speaker1.gmm')
    speaker = Diarize::Speaker.new(nil, nil, model_file)
    assert_equal speaker.model.name, 'S0'
  end

  def test_mean_log_likelihood
    speaker = Diarize::Speaker.ubm
    assert speaker.mean_log_likelihood.nan?
    speaker.mean_log_likelihood = 1
    assert_equal speaker.mean_log_likelihood, 1
  end

  def test_supervector
    speaker = Diarize::Speaker.new(nil, nil, File.join(File.dirname(__FILE__), 'data', 'speaker1.gmm'))
    assert_equal 512 * 24, speaker.supervector.dim
    # Testing the first and the last elements are OK
    assert_equal speaker.model.components[0].mean(0), speaker.supervector.vector[0]
    assert_equal speaker.model.components[511].mean(23), speaker.supervector.vector[512 * 24 - 1]
  end

  def test_save_and_load_model
    speaker = Diarize::Speaker.ubm
    tmp = Tempfile.new(['diarize-test', '.gmm'])
    speaker.save_model(tmp.path)
    model = Diarize::Speaker.load_model(tmp.path)
    assert_equal speaker.model.components[0].mean(0), model.components[0].mean(0)
    File.delete(tmp.path)
  end

  def test_divergence_returns_nil_if_one_model_is_empty
    speaker1 = Diarize::Speaker.ubm
    speaker2 = Diarize::Speaker.ubm
    speaker2.model = nil
    assert_equal Diarize::Speaker.divergence(speaker1, speaker2), nil
    assert_equal Diarize::Speaker.divergence(speaker2, speaker1), nil
  end

  def test_divergence_is_symmetric
    model_file = File.join(File.dirname(__FILE__), 'data', 'speaker1.gmm')
    speaker1 = Diarize::Speaker.new(nil, nil, model_file)
    speaker2 = Diarize::Speaker.ubm
    assert Diarize::Speaker.divergence(speaker1, speaker2) > 0
    assert_equal Diarize::Speaker.divergence(speaker1, speaker2), Diarize::Speaker.divergence(speaker2, speaker1)
    assert_equal Diarize::Speaker.divergence(speaker1, speaker1), 0.0
  end

  def test_divergence_ruby_is_same_as_divergence_lium
    model_file = File.join(File.dirname(__FILE__), 'data', 'speaker1.gmm')
    speaker1 = Diarize::Speaker.new(nil, nil, model_file)
    speaker2 = Diarize::Speaker.ubm
    assert_equal Diarize::Speaker.divergence_lium(speaker1, speaker2).round(12), Diarize::Speaker.divergence_ruby(speaker1, speaker2).round(12)
  end

  def test_normalise
    # Testing M-Norm
    model_file = File.join(File.dirname(__FILE__), 'data', 'speaker1.gmm')
    speaker1 = Diarize::Speaker.new(nil, nil, model_file)
    speaker2 = Diarize::Speaker.ubm
    assert Diarize::Speaker.divergence(speaker1, speaker2) != 1.0
    speaker1.normalize! # Putting speaker1.gmm at distance 1 from UBM
    assert Diarize::Speaker.divergence(speaker1, speaker2) - 1.0 < 1e-12 # rounding error
  end

  def test_do_not_normalize_ubm
    speaker = Diarize::Speaker.ubm
    old_supervector = speaker.supervector
    speaker.normalize!
    assert_equal old_supervector, speaker.supervector
  end

end
