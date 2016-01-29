
var LAYOUTS_PATH = "file://{resources}/layout/custom_game/{0}.xml";
var Objects = {};

Objects.Instantiate = function( name, id, parent )
{
	var newPanel = $.CreatePanel( "Panel", parent, id );
	var path = String.format(LAYOUTS_PATH, name);
	newPanel.BLoadLayout( path, false, false );
	return Objects.ConvertToObject( newPanel );
}

Objects.Define = function( data )
{
	var panel = $.GetContextPanel();
	Objects.Extend( panel, data );
	return panel;
}

Objects.ConvertToObject = function( panel )
{
	panel.extend = function( extension )
	{
		Objects.Extend( panel, extension );
	}
	return panel;
}

Objects.Extend = function( panel, extension )
{
	for (var key in extension)
	{
		panel[key] = extension[key];
	}
	return panel;
}

String.format = function(format)
{
	var args = Array.prototype.slice.call(arguments, 1);
	return format.replace(/{(\d+)}/g, function(match, number)
	{
		return typeof args[number] != 'undefined' ? args[number] : match;
	});
};

Array.contains = function(array, obj)
{
	for (var i = 0; i < array.length; i++)
	{
		if (array[i] === obj)
		{
			return true;
		}
	}
	return false;
}
