# encoding: UTF-8
# frozen_string_literal: true

##############################################################################
# Plugin Entry Point for YARD
# ============================================================================
# 
# While the library itself lives in the `YARD::StdLib` namespaces under the
# usual directory structure of `//lib/yard/link_stdlib`, when requiring
# plugins YARD will reach for `yard-link_stdlib`, basically just calling
# 
#     require 'yard-link_stdlib'
# 
# which leads it here. This is nice, because it lets us use the kind-of funkily
# 
##############################################################################


require_relative "./yard/link_stdlib"

YARD::LinkStdlib.install!
