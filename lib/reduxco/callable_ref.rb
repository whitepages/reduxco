module Reduxco
  # An immutable class that represents a referrence to a callable in a
  # CallableTable; this class is rarely used directly by clients.
  class CallableRef
    include Comparable

    # For string representations (typically used in debugging), this is
    # used as the separator between name and depth (if depth is given).
    SEPARATOR = ':'

    # [name] Typically the name is a symbol, but systems are free to use other
    #        objects as types are not coerced into other types at any point.
    #
    # [depth] The depth is normally not given when used, can be specified for
    #         referencing specific shadowed callables when callables are flattend
    #         into a CallableTable; this is important for calls to super.
    def initialize(name, depth=nil)
      @name = name
      @depth = depth
    end

    # Returns the name of the refernce.
    attr_reader :name

    # Returns the depth of the reference, or nil if the reference is dynamic.
    attr_reader :depth

    # Is true valued when the reference will dynamically bind to an entry
    # in the CallableTable instead of to an entry at a specific depth.
    def dynamic?
      return depth.nil?
    end

    # Negation of dynamic?
    def static?
      return !dynamic?
    end

    # Returns a unique hash value; useful resolving Hash entries.
    def hash
      @hash ||= self.to_a.hash
    end

    # Returns true if the passed ref is 
    #
    # This method raises an exception when compared to anything that does not
    # ducktype as a reference.
    def include?(other)
      other.name == self.name && (dynamic? ? true : other.depth == self.depth)
    end

    # Returns true if the refs are equivalent.
    def eql?(other)
      if( other.kind_of?(CallableRef) || (other.respond_to?(:name) && other.respond_to?(:depth)) )
        other.name == self.name && other.depth == self.depth
      else
        false
      end
    end
    alias_method :==, :eql?
    alias_method :===, :==

    # Returns the sort order of the reference.  This is primarily useed
    # for sorting references in CallableTable so that shadowed callables
    # are called properly.
    #
    # Static references are sorted by the following rule: For all sets of static
    # refs with equal names, sort by depth.  For all sets of static refs with
    # equal depths, only sort if the names are sortable.  This means that
    # there is no requirement for sort order to group by name or by depth, and
    # so no software should be written around an assumption of which comes first.
    #
    # Refuses to sort dynamic references, as they are not ordered compared to
    # static references.
    def <=>(other)
      if( dynamic? != other.dynamic? )
        nil
      else
        depth_eql = depth <=> other.depth
        (depth_eql==0 ? (name <=> other.name) : nil) || depth_eql
      end
    end

    def to_a
      @array ||= [name, depth]
    end

    def to_h
      @hash ||= {name:name, depth:depth}
    end

    def to_s
      @string ||= self.to_a.compact.map {|prop| prop.to_s}.join(SEPARATOR)
    end

    def inspect
      to_s
    end

  end
end
