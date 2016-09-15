<?php
/**
 * User: Alex Gusev <alex@flancer64.com>
 */

namespace Praxigento\App\Generic2\Console\Command\Init;

use Praxigento\App\Generic2\Config as Cfg;

/**
 * Initialize bonus parameters for Generic Application.
 */
class Bonus
    extends \Praxigento\App\Generic2\Console\Command\Init\Base
{
    /** @var  \Praxigento\Core\Transaction\Database\IManager */
    protected $_manTrans;
    /** @var  \Praxigento\BonusBase\Repo\Entity\Type\ICalc */
    protected $_repoBonusTypeCalc;
    /** @var \Praxigento\BonusBase\Service\IPeriod */
    protected $_callBonusPeriod;

    public function __construct(
        \Magento\Framework\ObjectManagerInterface $manObj,
        \Praxigento\Core\Transaction\Database\IManager $manTrans,
        \Praxigento\BonusBase\Repo\Entity\Type\ICalc $repoBonusTypeCalc,
        \Praxigento\BonusBase\Service\IPeriod $callBonusPeriod
    ) {
        parent::__construct(
            $manObj,
            'prxgt:app:init-bonus',
            'Initialize bonus parameters for Generic Application.'
        );
        $this->_manTrans = $manTrans;
        $this->_repoBonusTypeCalc = $repoBonusTypeCalc;
        $this->_callBonusPeriod = $callBonusPeriod;
    }

    protected function _initTypeCalc()
    {
        try {
            /** @var \Praxigento\BonusBase\Data\Entity\Type\Calc $data */
            $data = $this->_manObj->create(\Praxigento\BonusBase\Data\Entity\Type\Calc::class);
            $data->setCode(Cfg::CODE_TYPE_CALC_BONUS);
            $data->setNote('Bonus for Generic App');
            $this->_repoBonusTypeCalc->create($data);
        } catch (\Exception $e) {
            // do nothing if bonus already created
        }
    }

    protected function execute(
        \Symfony\Component\Console\Input\InputInterface $input,
        \Symfony\Component\Console\Output\OutputInterface $output
    ) {
        $def = $this->_manTrans->begin();
        try {
            $this->_initTypeCalc();
            /** @var \Praxigento\BonusBase\Service\Period\Request\GetForPvBasedCalc $req */
            $req = $this->_manObj->create(\Praxigento\BonusBase\Service\Period\Request\GetForPvBasedCalc::class);
            $req->setCalcTypeCode(Cfg::CODE_TYPE_CALC_BONUS);
            $resp = $this->_callBonusPeriod->getForPvBasedCalc($req);

            $this->_manTrans->commit($def);
        } finally {
            // transaction will be rolled back if commit is not done (otherwise - do nothing)
            $this->_manTrans->end($def);
        }
    }

}