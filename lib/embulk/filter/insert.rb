require 'json'
module Embulk
  module Filter

    class Insert < FilterPlugin
      Plugin.register_filter("insert", self)

      def self.transaction(config, in_schema, &control)
        task = {}

        column = config.param("column", :hash, default: nil)
        columns = config.param("columns", :array, default: nil)
        # ^ = XOR
        unless (column.nil? ^ columns.nil?)
          raise ArgumentError, "Either \"column\" or \"columns\" is needed"
        end

        if column
          columns = [ Insert.get_column(column) ]
        else
          columns = Insert.get_columns(columns)
        end

        task["values"] = columns.map{|c| c[:value] }

        at = config.param("at", :string, default: nil)
        before = config.param("before", :string, default: nil)
        after = config.param("after", :string, default: nil)

        if at.nil? and before.nil? and after.nil?
          at = "bottom"
        end

        no_of_position_param = 0
        no_of_position_param += 1 unless at.nil?
        no_of_position_param += 1 unless before.nil?
        no_of_position_param += 1 unless after.nil?

        unless no_of_position_param == 1
          raise ArgumentError, "Either \"at\", \"before\" or \"after\" is needed"
        end

        if at
          case at
          when "top", "head"
            task["position"] = 0
          when "bottom", "tail"
            task["position"] = in_schema.size
          else
            task["position"] = at.to_i
          end
        elsif before
          schema_cols = in_schema.select{|c| c.name == before }
          if schema_cols.empty?
            raise ArgumentError, "Column #{before} is not found"
          end
          task["position"] = schema_cols[0].index
        else
          schema_cols = in_schema.select{|c| c.name == after }
          if schema_cols.empty?
            raise ArgumentError, "Column #{after} is not found"
          end
          task["position"] = schema_cols[0].index + 1
        end

        # modify column definition
        inserted_schema = []
        columns.each{|c| inserted_schema.push(Column.new(0, c[:name], c[:type])) }
        out_columns = in_schema.map{|c| c }
        out_columns.insert(task["position"], *inserted_schema)

        # renumber index
        out_columns.each_with_index{|c, idx| c.index = idx }

        yield(task, out_columns)
      end

      # return { :name => name1, :value => value1, :type => type1 }
      def self.get_column(column_hash)
        if column_hash.size > 2
          raise ArgumentError, "Invalid column parameter: #{column_hash.to_s}"
        end

        # default type is string
        type = :string

        if column_hash.size == 2
          unless column_hash.keys.include?("as")
            raise ArgumentError, "Invalid column parameter: #{column_hash.to_s}"
          end
          type = column_hash["as"].to_sym
          column_hash = column_hash.select{|k, v| k != "as" }
        end

        column = {
          :name => column_hash.keys.first,
          :value => column_hash.values.first,
          :type => type
        }

        case type
        when :boolean
          column[:value] = (column[:value] != "false")
        when :long
          column[:value] = column[:value].to_i
        when :double
          column[:value] = column[:value].to_f
        when :string
          # do nothing
        when :timestamp
          column[:value] = Date.parse(column[:value])
        when :json
          column[:value] = JSON.parse(column[:value]) if column[:value]
        else
          raise ArgumentError, "Unknown type #{type}: supported types are boolean, long, double, string, timestamp and json"
        end

        column
      end

      # return array of column
      def self.get_columns(columns_array)
        columns_array.map{|column_hash| Insert.get_column(column_hash) }
      end

      def init
        @values = task["values"]
        @position = task["position"]
      end

      def close
      end

      def add(page)
        page.each do |record|
          record.insert(@position, *@values)
          page_builder.add(record)
        end
      end

      def finish
        page_builder.finish
      end
    end

  end
end
