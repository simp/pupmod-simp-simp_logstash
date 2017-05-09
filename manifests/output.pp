# A simple helper for including all of the default outputs with their default
# settings.
#
# @note Each output *must* have it's own class at
# `::simp_logstash::output::${name}` for this to work properly!
#
# You should manipulate the data of those classes with Hiera or your ENC.
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
define simp_logstash::output {
  include "::simp_logstash::output::${name}"
}
