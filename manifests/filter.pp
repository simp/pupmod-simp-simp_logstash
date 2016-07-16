# A simple helper for including all of the default filters with their default
# settings.
#
# @note Each filter *must* have it's own class at
# `::simp_logstash::filter::${name}` for this to work properly!
#
# You should manipulate the data of those classes with Hiera or your ENC.
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
# @copyright 2016 Onyx Point, Inc.
define simp_logstash::filter {
  include "::simp_logstash::filter::${name}"
}
