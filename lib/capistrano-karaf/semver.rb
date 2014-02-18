# Functions for semantic versions

module Semantic_Versions
  # Verify if the provided version is greater than the installed version
  #
  # Parameters
  #   - installed - a string containing the installed version
  #   - provided  - a string containging the provided version
  #
  # Example
  #   gt("2.18.0", "2.19.0")
  #   # returns true
  #
  # Returns a boolean which is true if the provided is greater than the installed
  def gt (installed, provided)
    compare(installed, provided) == :gt
  end

  # Verify if the provided version is less than the installed version
  #
  # Parameters
  #   - installed - a string containing the installed version
  #   - provided  - a string containging the provided version
  #
  # Example
  #   lt("2.18.0", "2.19.0")
  #   # returns false
  #
  # Returns a boolean which is true if the provided is less than the installed
  def lt (installed, provided)
    compare(installed, provided) == :lt
  end

  # Verify if the provided version is equal to the installed version
  #
  # Parameters
  #   - installed - a string containing the installed version
  #   - provided  - a string containging the provided version
  #
  # Example
  #   eq("2.18.0", "2.19.0")
  #   # returns false
  # 
  # Returns a boolean which is true if the provided is equal to the installed
  def eq (installed, provided)
    compare(installed, provided) == :eq
  end

  private
  def compare (installed, provided)
    installed_parts = installed.split('.')
    provided_parts = provided.split('.')
    
    installed_parts.zip(provided_parts).each do |versions|
      inst, prov = versions
      
      if inst.nil? then
        return :gt
      elsif prov.nil? then
        return :lt
      elsif inst < prov then
        return :gt
      elsif inst > prov then
        return :lt
      end
    end

    :eq
  end
end
