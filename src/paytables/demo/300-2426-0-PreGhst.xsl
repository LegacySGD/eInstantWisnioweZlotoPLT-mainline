<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:x="anything">
	<xsl:namespace-alias stylesheet-prefix="x" result-prefix="xsl" />
	<xsl:output encoding="UTF-8" indent="yes" method="xml" />
	<xsl:include href="../utils.xsl" />

	<xsl:template match="/Paytable">
		<x:stylesheet version="1.0" xmlns:java="http://xml.apache.org/xslt/java" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
			exclude-result-prefixes="java" xmlns:lxslt="http://xml.apache.org/xslt" xmlns:my-ext="ext1" extension-element-prefixes="my-ext">
			<x:import href="HTML-CCFR.xsl" />
			<x:output indent="no" method="xml" omit-xml-declaration="yes" />

			<!-- TEMPLATE Match: -->
			<x:template match="/">
				<x:apply-templates select="*" />
				<x:apply-templates select="/output/root[position()=last()]" mode="last" />
				<br />
			</x:template>

			<!--The component and its script are in the lxslt namespace and define the implementation of the extension. -->
			<lxslt:component prefix="my-ext" functions="formatJson,retrievePrizeTable,getType">
				<lxslt:script lang="javascript">
					<![CDATA[
					var debugFeed = [];
					var debugFlag = false;
					var bonusTotal = 0; 
					// Format instant win JSON results.
					// @param jsonContext String JSON results to parse and display.
					// @param translation Set of Translations for the game.
					function formatJson(jsonContext, translations, prizeTable, prizeValues, prizeNamesDesc)
					{
						var scenario = getScenario(jsonContext);
						var winningNums = getWinningNumbers(scenario);
						var outcomeNums = getOutcomeData(scenario, 0);
						var outcomePrizes = getOutcomeData(scenario, 1);
						var prizeNames = (prizeNamesDesc.substring(1)).split(',');
						var convertedPrizeValues = (prizeValues.substring(1)).split('|');
						//var bonusNames = ["N", "IW1", "IW2", "IW3", "IW4"];

						// Output winning numbers table.
						var booleanBonusGame = false;
						var booleanWheelGame = false;
						var r = [];
						r.push('<table border="0" cellpadding="2" cellspacing="1" width="50%" class="gameDetailsTable" style="table-layout:fixed">');
 						r.push('<tr><td class="tablehead" colspan="' + winningNums.length + '">');
 						r.push(getTranslationByName("luckyNumbers", translations));
 						r.push('</td></tr>');
 						r.push('<tr>');
 						for(var i = 0; i < winningNums.length; ++i)
 						{
 							r.push('<td class="tablebody">');
 							r.push(winningNums[i]);
 							r.push('</td>');
 						}
 						r.push('</tr>');
 						r.push('</table>');

						// Output outcome numbers table.
 						r.push('<table border="0" cellpadding="2" cellspacing="1" width="60%" class="gameDetailsTable" style="table-layout:fixed">');
						r.push('<tr>');
 						r.push('<td class="tablehead" width="25%">');
 						r.push(getTranslationByName("yourNumbers", translations));
 						r.push('</td>');
 						r.push('<td class="tablehead" width="25%">');
 						r.push(getTranslationByName("cashValues", translations));
						r.push('</td>');
 						r.push('</tr>');
						for(var i = 0; i < outcomeNums.length; ++i)
						{
							r.push('<tr>');
							r.push('<td class="tablebody" width="25%">');
							if (outcomeNums[i] == 'T') // represents the Collect Bonus symbol.
							{
								booleanBonusGame = true;
								r.push(getTranslationByName("prizeBonusTrigger", translations));
							}
							else if (outcomeNums[i] == 'U') // represents the Wheel Bonus symbol
							{
								booleanWheelGame = true;
								r.push(getTranslationByName("wheelBonusTrigger", translations));
							}
							else if (outcomeNums[i] == 'V' || outcomeNums[i] == 'W') // represents an instant win
							{
								r.push(getTranslationByName("instantWin", translations));
							}
							else
							{
 								r.push(translateOutcomeNumber(outcomeNums[i], translations));
							}
 							if(checkMatch(winningNums, outcomeNums[i]))
 							{
 								r.push(' - ' + getTranslationByName("matched", translations));
 							} 
 							r.push('</td>');
 							r.push('<td class="tablebody" width="25%">');
							if (outcomeNums[i] == 'W')
							{
 								r.push(convertedPrizeValues[getPrizeNameIndex(prizeNames, outcomePrizes[i])] + ' x 2 - ' + getTranslationByName("win", translations));
							}
							else
							{
 								r.push(convertedPrizeValues[getPrizeNameIndex(prizeNames, outcomePrizes[i])]);
 								if(checkMatch(winningNums, outcomeNums[i]) || outcomeNums[i] == 'V' || outcomeNums[i] == 'W')
 								{
 									r.push(' - ' + getTranslationByName("win", translations));
 								}	 
							}
							r.push('</td>');
 							r.push('</tr>');
						}
						r.push('</table>');

						if (booleanBonusGame)
						{
							var outcomeBonusGame = getBonusData(scenario);
							r.push('<table border="0" cellpadding="2" cellspacing="1" width="60%" class="gameDetailsTable" style="table-layout:fixed">');
							r.push('<tr>');
							r.push('<td class="tablehead" width="25%">');
 							r.push(getTranslationByName("prizeBonusWins", translations));
 							r.push('</td>');
							r.push('</tr>');

							for(var i = 0; i < outcomeBonusGame.length-1; ++i)
							{
								r.push('<tr>');
								r.push('<td class="tablebody" width="25%">');
 								r.push(convertedPrizeValues[getPrizeNameIndex(prizeNames, outcomeBonusGame[i])]);
								r.push('</td>');
 								r.push('</tr>');
							}
							r.push('</table>');
						}

						if (booleanWheelGame)
						{
							var outcomeWheelGame = getWheelData(scenario);
							r.push('<table border="0" cellpadding="2" cellspacing="1" width="60%" class="gameDetailsTable" style="table-layout:fixed">');
							r.push('<tr>');
							r.push('<td class="tablehead" width="25%">');
 							r.push(getTranslationByName("wheelBonusWins", translations));
 							r.push('</td>');
							r.push('</tr>');
					
							r.push('<tr>');
							r.push('<td class="tablebody" width="25%">');
 							r.push(convertedPrizeValues[getPrizeNameIndex(prizeNames, outcomeWheelGame[0])] + ' x ' + outcomeWheelGame[1]);
							r.push('</td>');
 							r.push('</tr>');

							r.push('</table>');
						}

						////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
						// !DEBUG OUTPUT TABLE
						if(debugFlag)
						{
							// DEBUG TABLE
							//////////////////////////////////////
							r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed">');
							for(var idx = 0; idx < debugFeed.length; ++idx)
 							{
								if(debugFeed[idx] == "")
									continue;
								r.push('<tr>');
 								r.push('<td class="tablebody">');
								r.push(debugFeed[idx]);
 								r.push('</td>');
	 							r.push('</tr>');
							}
							r.push('</table>');
						}
						return r.join('');
					}

					// Input: A list of Price Points and the available Prize Structures for the game as well as the wagered price point
					// Output: A string of the specific prize structure for the wagered price point
					function retrievePrizeTable(pricePoints, prizeStructures, wageredPricePoint)
					{
						var pricePointList = pricePoints.split(",");
						var prizeStructStrings = prizeStructures.split("|");


						for(var i = 0; i < pricePoints.length; ++i)
						{
							if(wageredPricePoint == pricePointList[i])
							{
								return prizeStructStrings[i];
							}
						}

						return "";
					}

					// Input: Json document string containing 'scenario' at root level.
					// Output: Scenario value.
					function getScenario(jsonContext)
					{
						// Parse json and retrieve scenario string.
						var jsObj = JSON.parse(jsonContext);
						var scenario = jsObj.scenario;

						// Trim null from scenario string.
						scenario = scenario.replace(/\0/g, '');

						return scenario;
					}

					// Input: Json document string containing 'amount' at root level.
					// Output: Price Point value.
					function getPricePoint(jsonContext)
					{
						// Parse json and retrieve price point amount
						var jsObj = JSON.parse(jsonContext);
						var pricePoint = jsObj.amount;

						return pricePoint;
					}

					// Input: "23,9,31|8:E,35:E,4:D,13:D,37:G,..."
					// Output: ["23", "9", "31"]
					function getWinningNumbers(scenario)
					{
						var numsData = scenario.split("|")[0];
						return numsData.split(",");
					}

					// Input: "23,9,31|8:E,35:E,4:D,13:D,37:G,..."
					// Output: ["8", "35", "4", "13", ...] or ["E", "E", "D", "G", ...]
					function getOutcomeData(scenario, index)
					{
						var outcomeData = scenario.split("|")[1];
						var outcomePairs = outcomeData.split(",");
						var outcomeResult = [];
						for(var i = 0; i < outcomePairs.length; ++i)
						{
							outcomeResult.push(outcomePairs[i].split(":")[index]);
						}
						return outcomeResult;
					}

					function getBonusData(scenario)
					{
						var bonusNumsData = scenario.split("|")[2];
						var bonusOutcomePairs = bonusNumsData.split(",");
						var bonusResult = [];
						for (var i = 0; i < bonusOutcomePairs.length; ++i)
						{
							bonusResult.push(bonusOutcomePairs[i]);
						}
						return bonusResult;
					}

					function getWheelData(scenario)
					{
						var wheelNumsData = scenario.split("|")[3];
						var wheelResult = [];
						if (wheelNumsData.length > 0)
						{
							wheelResult = wheelNumsData.split("*");
						}
						return wheelResult;
					}

					// Input: 'X', 'E', or number (e.g. '23')
					// Output: translated text or number.
					function translateOutcomeNumber(outcomeNum, translations)
					{
						if(outcomeNum == 'Z')
						{
							return getTranslationByName("winAll", translations);
						}
						else if (outcomeNum == 'Y')
						{
							return getTranslationByName(outcomeNum, translations);
						}
						else
						{
							return outcomeNum;
						}
					}

					// Input: List of winning numbers and the number to check
					// Output: true is number is contained within winning numbers or false if not
					function checkMatch(winningNums, boardNum)
					{
						for(var i = 0; i < winningNums.length; ++i)
						{
							// if(winningNums[i] == boardNum || boardNum == "V" || boardNum == "W")
							if(winningNums[i] == boardNum)
							{
								return true;
							}
						}

						return false;
					}

					// Input: "A,B,C,D,..." and "A"
					// Output: index number
					function getPrizeNameIndex(prizeNames, currPrize)
					{
						for(var i = 0; i < prizeNames.length; ++i)
						{
							if(prizeNames[i] == currPrize)
							{
								return i;
							}
						}
					}

					////////////////////////////////////////////////////////////////////////////////////////
					function registerDebugText(debugText)
					{
						debugFeed.push(debugText);
					}

					/////////////////////////////////////////////////////////////////////////////////////////
					function getTranslationByName(keyName, translationNodeSet)
					{
						var index = 1;
						while(index < translationNodeSet.item(0).getChildNodes().getLength())
						{
							var childNode = translationNodeSet.item(0).getChildNodes().item(index);
							
							if(childNode.name == "phrase" && childNode.getAttribute("key") == keyName)
							{
								registerDebugText("Child Node: " + childNode.name);
								return childNode.getAttribute("value");
							}
							
							index += 1;
						}
					}

					// Grab Wager Type
					// @param jsonContext String JSON results to parse and display.
					// @param translation Set of Translations for the game.
					function getType(jsonContext, translations)
					{
						// Parse json and retrieve wagerType string.
						var jsObj = JSON.parse(jsonContext);
						var wagerType = jsObj.wagerType;

						return getTranslationByName(wagerType, translations);
					}
					]]>
				</lxslt:script>
			</lxslt:component>

			<x:template match="root" mode="last">
				<table border="0" cellpadding="1" cellspacing="1" width="100%" class="gameDetailsTable">
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWager']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/WagerOutcome[@name='Game.Total']/@amount" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWins']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/PrizeOutcome[@name='Game.Total']/@totalPay" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
				</table>
			</x:template>

			<!-- TEMPLATE Match: digested/game -->
			<x:template match="//Outcome">
				<x:if test="OutcomeDetail/Stage = 'Scenario'">
					<x:call-template name="Scenario.Detail" />
				</x:if>
			</x:template>

			<!-- TEMPLATE Name: Scenario.Detail (base game) -->
			<x:template name="Scenario.Detail">
				<x:variable name="odeResponseJson" select="string(//ResultData/JSONOutcome[@name='ODEResponse']/text())" />
				<x:variable name="translations" select="lxslt:nodeset(//translation)" />
				<x:variable name="wageredPricePoint" select="string(//ResultData/WagerOutcome[@name='Game.Total']/@amount)" />
				<x:variable name="prizeTable" select="lxslt:nodeset(//lottery)" />

				<table border="0" cellpadding="0" cellspacing="0" width="100%" class="gameDetailsTable">
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='wagerType']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="my-ext:getType($odeResponseJson, $translations)" disable-output-escaping="yes" />
						</td>
					</tr>
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='transactionId']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="OutcomeDetail/RngTxnId" />
						</td>
					</tr>
				</table>
				<br />			
				
				<x:variable name="convertedPrizeValues">
					<x:apply-templates select="//lottery/prizetable/prize" mode="PrizeValue"/>
				</x:variable>

				<x:variable name="prizeNames">
					<x:apply-templates select="//lottery/prizetable/description" mode="PrizeDescriptions"/>
				</x:variable>


				<x:value-of select="my-ext:formatJson($odeResponseJson, $translations, $prizeTable, string($convertedPrizeValues), string($prizeNames))" disable-output-escaping="yes" />
			</x:template>

			<x:template match="prize" mode="PrizeValue">
					<x:text>|</x:text>
					<x:call-template name="Utils.ApplyConversionByLocale">
						<x:with-param name="multi" select="/output/denom/percredit" />
					<x:with-param name="value" select="text()" />
						<x:with-param name="code" select="/output/denom/currencycode" />
						<x:with-param name="locale" select="//translation/@language" />
					</x:call-template>
			</x:template>
			<x:template match="description" mode="PrizeDescriptions">
				<x:text>,</x:text>
				<x:value-of select="text()" />
			</x:template>

			<x:template match="text()" />
		</x:stylesheet>
	</xsl:template>

	<xsl:template name="TemplatesForResultXSL">
		<x:template match="@aClickCount">
			<clickcount>
				<x:value-of select="." />
			</clickcount>
		</x:template>
		<x:template match="*|@*|text()">
			<x:apply-templates />
		</x:template>
	</xsl:template>
</xsl:stylesheet>
