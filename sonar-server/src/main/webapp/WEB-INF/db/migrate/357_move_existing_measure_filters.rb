#
# Sonar, open source software quality management tool.
# Copyright (C) 2008-2012 SonarSource
# mailto:contact AT sonarsource DOT com
#
# Sonar is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 3 of the License, or (at your option) any later version.
#
# Sonar is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with Sonar; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02
#

#
# Sonar 3.4
#
class MoveExistingMeasureFilters < ActiveRecord::Migration

  # the new table
  class MeasureFilter < ActiveRecord::Base
  end

  # the old tables
  class FilterColumn < ActiveRecord::Base
    set_table_name 'filter_columns'
  end
  class Criteria < ActiveRecord::Base
    set_table_name 'criteria'
  end
  class Resource < ActiveRecord::Base
    set_table_name 'projects'
  end
  class OldFilter < ActiveRecord::Base
    set_table_name 'filters'
  end

  def self.up
    old_filters = OldFilter.find(:all)
    say_with_time "Moving #{old_filters.size} measure filters" do
      old_filters.each do |old_filter|
        move(old_filter)
      end
    end
  end

  private

  def self.move(old_filter)
    new_filter = MeasureFilter.new
    new_filter.name = old_filter.name
    new_filter.user_id = old_filter.user_id
    new_filter.shared = (old_filter.shared || old_filter.user_id.nil?)
    data = []
    data << 'onFavourites=true' if old_filter.favourites
    data << "baseId=#{old_filter.resource_id}" if old_filter.resource_id
    data << "pageSize=#{old_filter.page_size}" if old_filter.page_size
    data << "display=#{old_filter.default_view || 'list'}"

    move_columns(old_filter, data)
    move_criteria(old_filter, data)

    new_filter.data = data.join('|') unless data.empty?
    new_filter.save
    Filter.delete(old_filter.id)
  end

  def self.move_columns(old_filter, data)
    columns = []
    asc = nil
    sort = nil
    old_columns = FilterColumn.find(:all, :conditions => ['filter_id=?', old_filter.id], :order => 'order_index')
    old_columns.each do |old_column|
      column_key = old_column.family
      if old_column.kee
        column_key += ":#{old_column.kee}"
        column_key += ":#{old_filter.period_index}" if old_column.variation && old_filter.period_index
      end
      columns << column_key
      if old_column.sort_direction=='ASC'
        asc = true
        sort = column_key
      elsif old_column.sort_direction=='DESC'
        asc = false
        sort = column_key
      end
    end
    data << "cols=#{columns.join(',')}" unless columns.empty?
    if sort
      data << "sort=#{sort}"
      data << "asc=#{asc}"
    end
  end

  def self.move_criteria(old_filter, data)
    old_criteria = Criteria.find(:all, :conditions => ['filter_id=?', old_filter.id])
    metric_criteria_id=1

    old_criteria.each do |old|
      if old.family=='qualifier' && old.text_value.present?
        data << "qualifiers=#{old.text_value}"
      elsif old.family=='name' && old.text_value.present?
        data << "nameSearch=#{old.text_value}"
      elsif old.family=='key' && old.text_value.present?
        data << "keyRegexp=#{old.text_value}"
      elsif old.family=='language' && old.text_value.present?
        data << "languages=#{old.text_value}"
      elsif old.family=='date' && old.value && old.operator.present?
        data << "ageMaxDays=#{old.value}" if old.operator=='<'
        data << "ageMinDays=#{old.value}" if old.operator=='>'
      elsif old.family=='metric' && old.kee && old.operator && old.value
        data << "c#{metric_criteria_id}_metric=#{old.kee}"
        data << "c#{metric_criteria_id}_op=#{operator_code(old.operator)}"
        data << "c#{metric_criteria_id}_val=#{old.value}"
        data << "c#{metric_criteria_id}_period=#{old_filter.period_index}" if old_filter.period_index
        metric_criteria_id += 1
      elsif old.family=='direct-children' && old.text_value=='true'
        data << "onBaseComponents=true"
      end
    end
  end

  def self.operator_code(old_operator)
    case old_operator
      when '='
        'eq'
      when '<'
        'lt'
      when '<='
        'lte'
      when '>'
        'gt'
      when '>='
        'gte'
      else
        'eq'
    end
  end
end
