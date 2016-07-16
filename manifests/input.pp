# A simple helper for including all of the default inputs with their default
# settings.
#
# @note Each input *must* have it's own class at
# `::simp_logstash::input::${name}` for this to work properly!
#
# You should manipulate the data of those classes with Hiera or your ENC.
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
# @copyright 2016 Onyx Point, Inc.
define simp_logstash::input {
  include "::simp_logstash::input::${name}"
}
